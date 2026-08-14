import Testing

@testable import TerminalEmulator

@Suite struct ClipboardTmuxHintTests {
    @Test func tmuxWithoutSetClipboardShowsTheNamedHint() {
        let engine = ClipboardEngine(pasteboard: RecordingPasteboard())
        engine.noteTmuxDetected(true)
        engine.noteTmuxSetClipboardEnabled(false)

        #expect(engine.showsTmuxClipboardHint)
        #expect(engine.tmuxClipboardRefusal == .tmuxClipboardOff)

        let refusal = ClipboardRefusal.tmuxClipboardOff
        #expect(refusal.stateID == "app.tmuxClipboardOff")
        #expect(refusal.accessibilityIdentifier == "error.app.tmuxClipboardOff")
        #expect(refusal.copy.title == "tmux clipboard passthrough is off")
        #expect(
            refusal.copy.body
                == "tmux is on this host without clipboard passthrough, so remote copies never "
                + "reach this device. Add set -g set-clipboard on to your tmux.conf."
        )
        #expect(refusal.copy.recoveryLabel == "Dismiss")
    }

    @Test func theTmuxHintIsDistinctFromClipboardDenial() {
        let hint = ClipboardRefusal.tmuxClipboardOff
        let denial = ClipboardRefusal.denied

        #expect(hint.stateID != denial.stateID)
        #expect(hint.accessibilityIdentifier != denial.accessibilityIdentifier)
        #expect(hint.copy.title != denial.copy.title)
        #expect(hint.copy.body != denial.copy.body)
        #expect(denial.stateID == "app.clipboardDenied")
        #expect(denial.accessibilityIdentifier == "error.app.clipboardDenied")
    }

    @Test func enablingSetClipboardClearsTheHint() {
        let engine = ClipboardEngine(pasteboard: RecordingPasteboard())
        engine.noteTmuxDetected(true)
        engine.noteTmuxSetClipboardEnabled(true)

        #expect(!engine.showsTmuxClipboardHint)
        #expect(engine.tmuxClipboardRefusal == nil)
    }
}
