import AnySSHCore
import Foundation

public actor SSHRemoteConnection: RemoteConnection {
    public nonisolated let connectionID: ConnectionID
    public nonisolated let ledger = ControlChannelLedger()
    public nonisolated let gate = ControlChannelGate()

    public internal(set) var displayState = TransportState.idle
    public internal(set) var controlState = TransportState.idle
    public private(set) var notes = [TransportNote]()

    let profile: ConnectionProfile
    let credentials: ConnectionCredentials
    let hostKeys: any HostKeyStore

    var display: SSHTerminalTransport?
    var control: ControlTransport?
    var delegate: (any TerminalTransportDelegate)?
    var sink: (any ByteSink)?
    var size = TerminalSize.standard
    var isClosed = false

    var work = [Int: ControlWork]()
    var nextWorkID = 0
    var controlCancellationDepth = 0
    var lastControlActivity = ContinuousClock.now
    var idleSweeper: Task<Void, Never>?

    public internal(set) var cancellations = 0
    public internal(set) var lastCancellationReason: DisconnectReason?

    public init(
        profile: ConnectionProfile,
        credentials: ConnectionCredentials,
        hostKeys: any HostKeyStore
    ) {
        connectionID = profile.connectionID
        self.profile = profile
        self.credentials = credentials
        self.hostKeys = hostKeys
    }

    public var openChannelCount: Int {
        ledger.openCount
    }

    public internal(set) var clientPort: Int?

    public func setDisplaySink(_ sink: any ByteSink) async {
        self.sink = sink
        await display?.setSink(sink)
    }

    public func attachDisplay(sink: any ByteSink, size: TerminalSize) async throws {
        await setDisplaySink(sink)
        try await startDisplay(size: size)
    }

    public func setDisplayDelegate(_ delegate: any TerminalTransportDelegate) async {
        self.delegate = delegate
    }

    public func startDisplay(size: TerminalSize) async throws {
        guard !isClosed else { throw TransportFailure.connectionClosed }
        guard let sink else { throw TransportFailure.noSink }
        let transport = try await displayTransport()
        self.size = size
        await transport.setSink(sink)
        try await transport.start(size: size)
        clientPort = await transport.clientPort
    }

    public func sendDisplay(_ bytes: ArraySlice<UInt8>) async throws {
        guard let display else { throw TransportFailure.notConnected }
        try await display.send(bytes)
    }

    public func send(_ bytes: ArraySlice<UInt8>) async throws {
        try await sendDisplay(bytes)
    }

    public func resizeDisplay(to size: TerminalSize) async throws {
        self.size = size
        guard let display else { return }
        try await display.resize(to: size)
    }

    public func closeDisplay(reason: DisconnectReason = .closedByUser) async {
        guard let display else {
            displayState = .disconnected(reason)
            return
        }
        await display.close()
        self.display = nil
        displayState = .disconnected(reason)
    }

    public func reconnectDisplay() async throws {
        await closeDisplay(reason: .closedByUser)
        displayState = .connecting
        try await startDisplay(size: size)
    }

    public func close(reason: DisconnectReason = .closedByUser) async {
        isClosed = true
        await cancelAll(reason: reason)
        idleSweeper?.cancel()
        idleSweeper = nil
        await closeDisplay(reason: reason)
        if let control {
            await control.close(reason: reason)
        }
        control = nil
        controlState = .disconnected(reason)
    }

    func displayTransport() async throws -> SSHTerminalTransport {
        if let display { return display }
        let transport = SSHTerminalTransport(
            target: profile.target,
            username: profile.username,
            credential: try await credential(for: .display),
            hostKeys: hostKeys,
            configuration: profile.display
        )
        await transport.setDelegate(self)
        if let sink { await transport.setSink(sink) }
        display = transport
        return transport
    }

    func credential(for side: ConnectionSide) async throws -> AuthCredential {
        let isFirst = await credentials.issued == 0
        let credential = try await credentials.credential()
        if let note = ConnectionPrompting.note(
            for: credential,
            dialling: side,
            isFirstTransport: isFirst
        ) {
            notes.append(note)
        }
        return credential
    }
}
