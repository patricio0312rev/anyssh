#if canImport(UIKit)
import AnySSHCore
import Foundation
import SwiftUI

extension SessionWorkspaceView {
    @ViewBuilder
    var switcherOverlay: some View {
        if isSwitcherPresented {
            SessionSwitcherView(
                model: model,
                onSwitch: handleSwitch,
                onDismiss: dismissSwitcher,
                onOpenJobAlerts: model.jobAlerts == nil ? nil : { isJobAlertsPresented = true }
            )
            .transition(.opacity)
            .zIndex(1)
        }
    }

    @ViewBuilder
    var paletteOverlay: some View {
        if isPalettePresented {
            CommandPaletteView(
                entries: paletteEntries,
                onActivate: runCommand,
                onDismiss: dismissPalette
            )
            .transition(.opacity)
            .zIndex(2)
        }
    }

    var paletteEntries: [PaletteEntry] {
        commandRegistry.commands.map { command in
            PaletteEntry(
                id: command.id,
                title: command.title,
                keyLabel: command.keyEquivalent?.label,
                isEnabled: command.isEnabled(),
                disabledReason: command.disabledReason()
            )
        }
    }

    func presentSwitcher() {
        withAnimation(Theme.Motion.overlay) { isSwitcherPresented = true }
    }

    func toggleSwitcher() {
        if isSwitcherPresented { dismissSwitcher() } else { presentSwitcher() }
    }

    func runCommand(_ id: String) {
        commandRegistry.run(id: id)
        isPalettePresented = false
        reclaimHardwareKeyboard()
    }

    func handleSwitch(_ id: SessionID) {
        model.beginSwitch(to: id)
        isSwitcherPresented = false
        reclaimHardwareKeyboard()
        Task { await model.completeSwitch() }
    }

    func dismissSwitcher() {
        isSwitcherPresented = false
        reclaimHardwareKeyboard()
    }

    func dismissPalette() {
        isPalettePresented = false
        reclaimHardwareKeyboard()
    }

    func reclaimHardwareKeyboard() {
        NotificationCenter.default.post(name: .anySSHReclaimHardwareKeyboard, object: nil)
    }
}
#endif
