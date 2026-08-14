import Testing

@testable import TerminalEmulator

@Suite struct ClipboardPasteCancelTests {
    @Test func fortyLinePlanConfirmsAndCancelMapsToZeroBytes() {
        let text = (1...40).map { "line \($0)" }.joined(separator: "\n")
        let plan = PasteConfirmation.plan(for: text)

        guard case .confirm(let payload) = plan else {
            Issue.record("expected confirmation")
            return
        }
        #expect(payload.lineCount == 40)
        #expect(PasteConfirmationContent(payload: payload).lineCount == 40)

        var sent: [[UInt8]] = []
        #expect(sent.isEmpty)
        #expect(ClipboardRefusal.pasteCancelled.stateID == "app.pasteCancelled")
    }
}
