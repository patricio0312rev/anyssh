import AnySSHCore
import SwiftUI
import TerminalEmulator

public struct ClipboardScenarioView: View {
    public enum Kind: String, Sendable {
        case copy
        case tmuxHint
        case pasteConfirm
    }

    @State private var controller: ClipboardController
    @State private var statusToasts = StatusToastCenter()
    @State private var localPasteboard = ""
    @State private var outboundEncoded = ""
    @State private var pasteByteCount = "0"
    private let kind: Kind
    private let selectionText: String
    private let transportLog: ClipboardTransportLog

    public init(
        kind: Kind,
        selectionText: String = "selected terminal text",
        pasteText: String? = nil
    ) {
        self.kind = kind
        self.selectionText = selectionText
        let lines = (1...40).map { "line \($0)" }.joined(separator: "\n")
        let gate: any ClipboardPasteGate =
            switch kind {
            case .pasteConfirm:
                ScriptedClipboardPasteGate(text: pasteText ?? lines)
            case .copy, .tmuxHint:
                ScriptedClipboardPasteGate(.empty)
            }
        let log = ClipboardTransportLog()
        self.transportLog = log
        let board: any ClipboardPasteboard =
            kind == .copy ? SystemClipboardPasteboard() : MemoryClipboardPasteboard()
        _controller = State(
            initialValue: ClipboardController(
                pasteboard: board,
                pasteGate: gate,
                sendBytes: { log.append($0) }
            )
        )
    }

    public var body: some View {
        ClipboardSurface(controller: controller) {
            Group {
                switch kind {
                case .copy:
                    copyBody
                case .tmuxHint:
                    Color.clear.onAppear {
                        controller.noteTmux(detected: true, setClipboardEnabled: false)
                    }
                case .pasteConfirm:
                    pasteBody
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.surface.base)
        }
        .statusToastHost(center: statusToasts)
    }

    private var copyBody: some View {
        VStack(spacing: 16) {
            SelectionCopyButton(text: selectionText) { text in
                controller.engine.markRemoteClipboardActive()
                controller.copySelection(text)
                outboundEncoded = String(decoding: transportLog.joined, as: UTF8.self)
                localPasteboard = SystemClipboardPasteboard().read() ?? ""
            }
            Text(outboundEncoded)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.text.tertiary)
                .accessibilityIdentifier("terminal.clipboard.outbound")
                .accessibilityValue(outboundEncoded)

            Text(localPasteboard)
                .frame(width: 1, height: 1)
                .clipped()
                .opacity(0)
                .accessibilityIdentifier("terminal.clipboard.local")
                .accessibilityValue(localPasteboard)
        }
    }

    private var pasteBody: some View {
        Text(pasteByteCount)
            .accessibilityIdentifier("terminal.paste.bytesSent")
            .accessibilityValue(pasteByteCount)
            .task {
                await controller.beginPaste()
            }
            .onChange(of: controller.pendingPaste?.text) { _, _ in
                pasteByteCount = "\(controller.pasteBytesSent.count)"
            }
            .onChange(of: controller.refusal?.stateID) { _, _ in
                pasteByteCount = "\(controller.pasteBytesSent.count)"
            }
    }
}
