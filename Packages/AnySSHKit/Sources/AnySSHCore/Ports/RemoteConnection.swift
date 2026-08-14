public protocol RemoteConnection: Actor, RemoteCommandRunner, DisplayWriter {
    nonisolated var connectionID: ConnectionID { get }

    var displayState: TransportState { get }
    var controlState: TransportState { get }

    var openChannelCount: Int { get }

    var clientPort: Int? { get }

    func cancelAll(reason: DisconnectReason) async

    func close(reason: DisconnectReason) async

    func attachDisplay(sink: any ByteSink, size: TerminalSize) async throws

    func setDisplayDelegate(_ delegate: any TerminalTransportDelegate) async

    func sendDisplay(_ bytes: ArraySlice<UInt8>) async throws

    func resizeDisplay(to size: TerminalSize) async throws
}
