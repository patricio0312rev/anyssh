import AnySSHUI
import SwiftUI

struct TerminalScenarioView: View {
    let scenario: TerminalScenario

    var body: some View {
        switch scenario {
        case .gestures:
            TerminalGestureScenarioView()
        case .links:
            TerminalLinkScenarioView()
        case .clipboard:
            ClipboardScenarioView(kind: .copy)
        case .clipboardTmuxHint:
            ClipboardScenarioView(kind: .tmuxHint)
        case .pasteConfirm:
            ClipboardScenarioView(kind: .pasteConfirm)
        }
    }
}
