import Testing

@testable import TerminalEmulator

@Suite struct PasteConfirmationTests {
    @Test func fortyLinesRequireConfirmationWithThatCount() {
        let text = (1...40).map { "line \($0)" }.joined(separator: "\n")
        let plan = PasteConfirmation.plan(for: text)

        guard case .confirm(let payload) = plan else {
            Issue.record("expected confirmation for 40 lines")
            return
        }
        #expect(payload.lineCount == 40)
        let content = PasteConfirmationContent(payload: payload)
        #expect(content.lineCount == 40)
        #expect(content.preview.contains("line 1"))
    }

    @Test func aSingleLineSendsImmediately() {
        let plan = PasteConfirmation.plan(for: "echo hi")
        guard case .sendImmediately(let payload) = plan else {
            Issue.record("expected immediate send")
            return
        }
        #expect(payload.lineCount == 1)
    }

    @Test func cancelMapsToThePasteCancelledRefusal() {
        #expect(ClipboardRefusal.pasteCancelled.stateID == "app.pasteCancelled")
        #expect(ClipboardRefusal.pasteCancelled.copy.title == "Paste cancelled")
        #expect(
            ClipboardRefusal.pasteCancelled.copy.body
                == "Nothing was pasted, and nothing was sent to the host."
        )
    }
}
