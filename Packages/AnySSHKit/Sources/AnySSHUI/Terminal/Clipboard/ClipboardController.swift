import AnySSHCore
import Observation
import TerminalEmulator

@MainActor
@Observable
public final class ClipboardController {
    public private(set) var pendingPaste: PastePayload?
    public private(set) var refusal: ClipboardRefusal?

    public let engine: ClipboardEngine
    private let pasteGate: any ClipboardPasteGate
    private let inputMode: () -> TerminalInputMode
    private let sendBytes: ([UInt8]) -> Void
    private let pasteLog: ClipboardTransportLog
    private var outboundCursor = 0

    public init(
        pasteboard: any ClipboardPasteboard = SystemClipboardPasteboard(),
        pasteGate: any ClipboardPasteGate,
        chunkBytes: Int = OSC52Limits.transportChunkBytes,
        maxDecodedBytes: Int = OSC52Limits.maxDecodedBytes,
        inputMode: @escaping () -> TerminalInputMode = { TerminalInputMode() },
        sendBytes: @escaping ([UInt8]) -> Void
    ) {
        self.pasteGate = pasteGate
        self.inputMode = inputMode
        self.sendBytes = sendBytes
        self.pasteLog = ClipboardTransportLog()
        self.engine = ClipboardEngine(
            pasteboard: pasteboard,
            maxDecodedBytes: maxDecodedBytes,
            chunkBytes: chunkBytes
        )
    }

    public var transportLog: [[UInt8]] {
        engine.transportLog.snapshot() + pasteLog.snapshot()
    }

    public var pasteBytesSent: [UInt8] {
        pasteLog.joined
    }

    @discardableResult
    public func handleInbound(_ bytes: ArraySlice<UInt8>) -> OSC52Inbound.Outcome {
        applyInbound(engine.feed(bytes))
    }

    @discardableResult
    public func handleDecodedInbound(_ text: String) -> OSC52Inbound.Outcome {
        applyInbound(engine.feedDecoded(text))
    }

    public func noteRemoteClipboardQuery() {
        engine.markRemoteClipboardActive()
    }

    public func copySelection(_ text: String) {
        engine.copySelection(text)
        flushOutbound()
    }

    public func beginPaste() async {
        apply(await pasteGate.requestPaste())
    }

    public func apply(_ access: ClipboardPasteAccess) {
        switch access {
        case .denied:
            refusal = .denied
        case .empty:
            break
        case .allowed(let text):
            switch PasteConfirmation.plan(for: text) {
            case .sendImmediately(let payload):
                emitPaste(payload)
            case .confirm(let payload):
                pendingPaste = payload
            }
        }
    }

    public func confirmPaste() {
        guard let payload = pendingPaste else { return }
        pendingPaste = nil
        emitPaste(payload)
    }

    public func cancelPaste() {
        pendingPaste = nil
        refusal = .pasteCancelled
    }

    public func dismissRefusal() {
        refusal = nil
    }

    public func noteTmux(detected: Bool, setClipboardEnabled: Bool) {
        engine.noteTmuxDetected(detected)
        engine.noteTmuxSetClipboardEnabled(setClipboardEnabled)
        if engine.showsTmuxClipboardHint {
            refusal = .tmuxClipboardOff
        }
    }

    public var confirmationContent: PasteConfirmationContent? {
        pendingPaste.map { PasteConfirmationContent(payload: $0) }
    }

    private func applyInbound(_ outcome: OSC52Inbound.Outcome) -> OSC52Inbound.Outcome {
        if case .refused(let reason) = outcome {
            refusal = reason
        }
        flushOutbound()
        return outcome
    }

    private func emitPaste(_ payload: PastePayload) {
        let bytes = payload.bytes(mode: inputMode())
        pasteLog.append(bytes)
        sendBytes(bytes)
    }

    private func flushOutbound() {
        let chunks = engine.transportLog.snapshot()
        guard outboundCursor < chunks.count else { return }
        for chunk in chunks[outboundCursor...] {
            sendBytes(chunk)
        }
        outboundCursor = chunks.count
    }
}
