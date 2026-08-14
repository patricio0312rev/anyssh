#if canImport(UIKit)
import SwiftUI
import Testing

@testable import AnySSHUI

@Suite @MainActor struct PaletteSnapshotTests {
    private let entries = [
        PaletteEntry(
            id: "app.newConnection",
            title: "New Connection",
            keyLabel: "Cmd+N",
            isEnabled: true,
            disabledReason: nil
        ),
        PaletteEntry(
            id: "session.next",
            title: "Next Session",
            keyLabel: nil,
            isEnabled: true,
            disabledReason: nil
        ),
        PaletteEntry(
            id: "session.activateTwo",
            title: "Session 2",
            keyLabel: "Cmd+2",
            isEnabled: false,
            disabledReason: "One session open"
        ),
        PaletteEntry(
            id: "app.openJumpTo",
            title: "Open Jump to",
            keyLabel: nil,
            isEnabled: false,
            disabledReason: "Available in a later build"
        ),
    ]

    @Test func emptyState() {
        ComponentSnapshot.assert(palette(query: "zzz"), named: "palette-empty", height: 420)
    }

    @Test func filteredList() {
        ComponentSnapshot.assert(palette(query: "ses"), named: "palette-filtered", height: 420)
    }

    @Test func disabledRow() {
        ComponentSnapshot.assert(palette(query: ""), named: "palette-disabled", height: 420)
    }

    private func palette(query: String) -> some View {
        CommandPaletteView(
            entries: entries,
            initialQuery: query,
            onActivate: { _ in },
            onDismiss: {}
        )
    }
}
#endif
