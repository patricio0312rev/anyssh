#if canImport(UIKit)
import SwiftUI
import Testing

@testable import AnySSHUI

@Suite @MainActor struct ButtonSnapshotTests {
    @Test func iconButtonSurfaces() {
        ComponentSnapshot.assert(
            HStack(spacing: Theme.Space.step4) {
                IconButton(systemImage: "gearshape", label: "Settings", surface: .inline) {}
                IconButton(systemImage: "plus", label: "Add host", surface: .inline) {}
                IconButton(systemImage: "square.and.arrow.up", label: "Share", surface: .toolbar) {}
            },
            named: "iconButton-surfaces",
            height: 120
        )
    }

    @Test func closeButtonHasOneSize() {
        ComponentSnapshot.assert(
            HStack(spacing: Theme.Space.step4) {
                CloseButton(accessibilityIdentifier: "snapshot.close.a") {}
                CloseButton(accessibilityIdentifier: "snapshot.close.b") {}
            },
            named: "closeButton",
            height: 120
        )
    }

    @Test func wrapToggleBothStates() {
        ComponentSnapshot.assert(
            HStack(spacing: Theme.Space.step4) {
                WrapToggle(wrapsLines: .constant(true))
                WrapToggle(wrapsLines: .constant(false))
            },
            named: "wrapToggle",
            height: 120
        )
    }
}
#endif
