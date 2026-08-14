import AnySSHCore
import Foundation

public final class ClipboardEngine: @unchecked Sendable {
    public let transportLog: ClipboardTransportLog

    private let lock = NSLock()
    private var remoteActive = false
    private var tmuxIsPresent = false
    private var tmuxClipboardOn = false
    private var refusal: ClipboardRefusal?

    private let pasteboard: any ClipboardPasteboard
    private let maxDecodedBytes: Int
    private let chunkBytes: Int
    private let onTransportWrite: @Sendable ([UInt8]) -> Void

    public init(
        pasteboard: any ClipboardPasteboard,
        transportLog: ClipboardTransportLog = ClipboardTransportLog(),
        maxDecodedBytes: Int = OSC52Limits.maxDecodedBytes,
        chunkBytes: Int = OSC52Limits.transportChunkBytes,
        onTransportWrite: @escaping @Sendable ([UInt8]) -> Void = { _ in }
    ) {
        self.pasteboard = pasteboard
        self.transportLog = transportLog
        self.maxDecodedBytes = maxDecodedBytes
        self.chunkBytes = chunkBytes
        self.onTransportWrite = onTransportWrite
    }

    public var remoteClipboardActive: Bool {
        lock.withLock { remoteActive }
    }

    public var tmuxDetected: Bool {
        lock.withLock { tmuxIsPresent }
    }

    public var tmuxSetClipboardEnabled: Bool {
        lock.withLock { tmuxClipboardOn }
    }

    public var lastRefusal: ClipboardRefusal? {
        lock.withLock { refusal }
    }

    public var showsTmuxClipboardHint: Bool {
        lock.withLock { tmuxIsPresent && !tmuxClipboardOn }
    }

    public var tmuxClipboardRefusal: ClipboardRefusal? {
        showsTmuxClipboardHint ? .tmuxClipboardOff : nil
    }

    @discardableResult
    public func feed(_ bytes: ArraySlice<UInt8>) -> OSC52Inbound.Outcome {
        record(
            OSC52Inbound.handle(
                sequence: bytes,
                pasteboard: pasteboard,
                maxDecodedBytes: maxDecodedBytes
            ))
    }

    @discardableResult
    public func feedDecoded(_ text: String) -> OSC52Inbound.Outcome {
        record(
            OSC52Inbound.handle(
                decodedText: text,
                pasteboard: pasteboard,
                maxDecodedBytes: maxDecodedBytes
            ))
    }

    public func copySelection(_ text: String) {
        pasteboard.write(text)
        guard remoteClipboardActive else { return }
        emitOutbound(text)
    }

    public func pushLocalClipboard() {
        guard let text = pasteboard.read() else { return }
        emitOutbound(text)
    }

    public func markRemoteClipboardActive() {
        lock.withLock { remoteActive = true }
    }

    public func noteTmuxDetected(_ detected: Bool) {
        lock.withLock { tmuxIsPresent = detected }
    }

    public func noteTmuxSetClipboardEnabled(_ enabled: Bool) {
        lock.withLock { tmuxClipboardOn = enabled }
    }

    private func record(_ outcome: OSC52Inbound.Outcome) -> OSC52Inbound.Outcome {
        switch outcome {
        case .wrote, .query:
            lock.withLock {
                remoteActive = true
                refusal = nil
            }
        case .refused(let reason):
            lock.withLock { refusal = reason }
        case .ignored:
            break
        }
        if case .query = outcome {
            emitOutbound(pasteboard.read() ?? "")
        }
        return outcome
    }

    private func emitOutbound(_ text: String) {
        for chunk in OSC52Outbound.chunks(for: text, chunkBytes: chunkBytes) {
            transportLog.append(chunk)
            onTransportWrite(chunk)
        }
    }
}
