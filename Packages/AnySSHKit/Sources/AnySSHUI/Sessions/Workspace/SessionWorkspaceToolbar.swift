#if canImport(UIKit)
import AnySSHCore
import SwiftUI

struct SessionWorkspaceToolbar: ToolbarContent {
    let title: String
    let transportState: TransportState
    let keyboardEngine: (any TerminalSurfaceEngine)?
    let showsBack: Bool
    let onBack: () -> Void
    let onToggleSwitcher: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if showsBack {
                IconButton(
                    systemImage: "chevron.backward",
                    label: "Back to remotes",
                    surface: .toolbar,
                    accessibilityIdentifier: SessionSwitcherIdentifier.close,
                    action: onBack
                )
            }
        }
        ToolbarItem(placement: .principal) {
            Button(action: onToggleSwitcher) {
                SessionNavbarChrome(title: title, transportState: transportState)
            }
            .accessibilityLabel("Switch session, \(title)")
            .accessibilityIdentifier(SessionSwitcherIdentifier.title)
            .buttonStyle(.plain)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if let keyboardEngine {
                TerminalKeyboardToggle(engine: keyboardEngine)
            }
        }
    }
}
#endif
