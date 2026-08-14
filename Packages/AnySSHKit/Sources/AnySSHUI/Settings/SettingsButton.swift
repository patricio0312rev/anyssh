import SwiftUI

extension View {
    func settingsButton(floatsOverContent: Bool, open: @escaping () -> Void) -> some View {
        overlay(alignment: .bottomTrailing) {
            IconButton(
                systemImage: "gearshape",
                label: "Settings",
                surface: floatsOverContent ? .inline : .raised,
                accessibilityIdentifier: UIIdentifier.Settings.open,
                action: open
            )
            .padding(.trailing, Theme.Space.screenMargin)
            .padding(.bottom, Theme.Space.screenMargin)
        }
    }
}
