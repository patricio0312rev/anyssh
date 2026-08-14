import AnySSHCore
import TerminalEmulator

@MainActor
final class TerminalSurfaceBridge: TerminalEngineDelegate {
    private var connection: any RemoteConnection
    private let metadata: TerminalMetadataCoalescer
    private var resize: ResizeCoordinator
    var onWriteFailure: ((any Error) -> Void)?

    init(connection: any RemoteConnection, metadata: TerminalMetadataCoalescer) {
        self.connection = connection
        self.metadata = metadata
        resize = Self.makeResize(for: connection)
    }

    func rebind(to connection: any RemoteConnection) {
        self.connection = connection
        resize = Self.makeResize(for: connection)
    }

    func engine(_ engine: any TerminalEngine, didChangeTitle title: String) {
        metadata.record(title: title)
    }

    func engine(_ engine: any TerminalEngine, didReportWorkingDirectory path: String) {
        metadata.record(workingDirectory: path)
    }

    func engine(_ engine: any TerminalEngine, didRequestClipboardWrite text: String) {
        _ = text
    }

    func engineDidRequestClipboardRead(_ engine: any TerminalEngine) -> String? {
        nil
    }

    func engineDidRing(_ engine: any TerminalEngine) {
        metadata.recordBell()
    }

    func engine(_ engine: any TerminalEngine, didProduceInput bytes: ArraySlice<UInt8>) {
        let payload = Array(bytes)
        let connection = connection
        Task { [weak self] in
            do {
                try await connection.sendDisplay(payload[...])
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run { self?.onWriteFailure?(error) }
            }
        }
    }

    func engine(_ engine: any TerminalEngine, didResizeTo size: TerminalSize) {
        resize.sizeChanged(to: size)
    }

    private static func makeResize(for connection: any RemoteConnection) -> ResizeCoordinator {
        ResizeCoordinator { size in
            try? await connection.resizeDisplay(to: size)
        }
    }
}
