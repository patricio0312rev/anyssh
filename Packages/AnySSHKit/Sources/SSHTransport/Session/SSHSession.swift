import AnySSHCore
import CSSH
import Darwin
import Foundation

public actor SSHSession {
    public static let waitSlice = Duration.milliseconds(250)

    public let target: SessionTarget

    public let trust: HostKeyTrust

    public private(set) var state: TransportState = .idle
    public private(set) var notes = [TransportNote]()
    public private(set) var resolvedAddress: ResolvedAddress?
    public private(set) var connectRoundTrip: Duration?
    public internal(set) var trustOutcome: HostKeyTrustOutcome?
    public internal(set) var diagnostics = SessionDiagnostics()

    let configuration: SSHSessionConfiguration
    var handle: OpaquePointer?
    var descriptor: Int32 = -1
    var lastInbound = ContinuousClock.now
    private(set) var generation = 0

    public init(
        target: SessionTarget,
        configuration: SSHSessionConfiguration = .init(),
        trust: HostKeyTrust = .unattended
    ) {
        self.target = target
        self.configuration = configuration
        self.trust = trust
    }

    public var remoteBanner: String? {
        guard let handle, let banner = libssh2_session_banner_get(handle) else { return nil }
        return String(cString: banner)
    }

    public var isDialled: Bool {
        descriptor >= 0
    }

    public var timeSinceLastInbound: Duration {
        lastInbound.duration(to: .now)
    }

    @discardableResult
    public func open() async throws -> HostKeyTrustOutcome {
        try await dial()
        return try await handshake()
    }

    public func dial() async throws {
        teardown()
        state = .connecting
        let generation = self.generation
        do {
            let addresses = try await resolveAddresses()
            let result = try await SessionSocket.dial(
                addresses,
                host: target.host,
                timeout: configuration.connectTimeout
            )
            guard adopt(result, from: generation) else { throw TransportFailure.notConnected }
        } catch {
            throw record(error)
        }
    }

    func adopt(_ result: DialResult, from generation: Int) -> Bool {
        guard generation == self.generation else {
            SessionSocket.close(result.descriptor)
            return false
        }
        descriptor = result.descriptor
        resolvedAddress = result.address
        connectRoundTrip = result.roundTrip
        lastInbound = .now
        return true
    }

    @discardableResult
    public func handshake() async throws -> HostKeyTrustOutcome {
        try await exchangeKeys()
        let outcome = try await gateOnHostKey()
        noteInboundActivity()
        state = .connected
        return outcome
    }

    public func close(reason: DisconnectReason = .closedByUser) {
        teardown()
        state = .disconnected(reason)
    }

    isolated deinit {
        if let handle { libssh2_session_free(handle) }
        SessionSocket.close(descriptor)
    }

    func teardown() {
        generation += 1
        trustOutcome = nil
        if let handle {
            libssh2_session_set_timeout(handle, 2000)
            libssh2_session_set_blocking(handle, 1)
            libssh2_session_disconnect_ex(handle, SSH_DISCONNECT_BY_APPLICATION, "anyssh", "")
            libssh2_session_free(handle)
        }
        handle = nil
        SessionSocket.close(descriptor)
        descriptor = -1
    }

    func noteInboundActivity() {
        lastInbound = .now
    }

    private func resolveAddresses() async throws -> [ResolvedAddress] {
        do {
            return try await AddressResolver.addresses(host: target.host, port: target.port)
        } catch {
            guard let fallback = target.fallbackAddress, fallback != target.host else { throw error }
            let addresses = try await AddressResolver.addresses(host: fallback, port: target.port)
            notes.append(.dnsFallback(name: target.host, address: fallback))
            return addresses
        }
    }

    func record(_ error: some Error) -> Error {
        guard case .disconnected = state else {
            let stateID = (error as? any UserFacingError)?.stateID ?? "transport.connectionLost"
            state = .disconnected(.failed(stateID: stateID))
            return error
        }
        return error
    }
}
