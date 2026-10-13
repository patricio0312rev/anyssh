import AnySSHCore
import Foundation

struct GatedCredential: Sendable {
    let authenticator: any BiometricAuthenticator
    let secrets: any SecretStore
    let reference: SecretReference
}

actor CountingBiometrics: BiometricAuthenticator {
    private(set) var authentications = 0

    func authenticate(reason: String) async -> BiometricResult {
        _ = reason
        authentications += 1
        return BiometricResult(.authenticated)
    }
}

actor BiometricGatedConnection: RemoteConnection {
    private static let unlockReason = "Unlock the key passphrase"

    nonisolated let connectionID: ConnectionID
    private let credential: GatedCredential?

    private(set) var displayState = TransportState.idle
    private(set) var controlState = TransportState.idle
    private(set) var openChannelCount = 0
    var clientPort: Int? { nil }

    init(connectionID: ConnectionID, credential: GatedCredential? = nil) {
        self.connectionID = connectionID
        self.credential = credential
    }

    func attachDisplay(sink: any ByteSink, size: TerminalSize) async throws {
        _ = sink
        _ = size
        try await unlock()
        displayState = .connected
    }

    func setDisplayDelegate(_ delegate: any TerminalTransportDelegate) async {
        _ = delegate
    }

    func sendDisplay(_ bytes: ArraySlice<UInt8>) async throws {
        _ = bytes
    }

    func send(_ bytes: ArraySlice<UInt8>) async throws {
        _ = bytes
    }

    func resizeDisplay(to size: TerminalSize) async throws {
        _ = size
    }

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        _ = batch
        throw ErrorState.transport(.connectionRefused)
    }

    func cancelAll(reason: DisconnectReason) async {
        _ = reason
    }

    func close(reason: DisconnectReason) async {
        displayState = .disconnected(reason)
        controlState = .disconnected(reason)
    }

    private func unlock() async throws {
        guard let credential else { return }
        let result = await credential.authenticator.authenticate(reason: Self.unlockReason)
        guard result.outcome == .authenticated else { throw SecretStoreError.biometricCancelled }
        _ = try await credential.secrets.secret(credential.reference)
    }
}
