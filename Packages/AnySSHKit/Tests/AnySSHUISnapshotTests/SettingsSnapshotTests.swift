#if canImport(UIKit)
import AnySSHCore
import Foundation
import SwiftUI
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SettingsSnapshotTests {
    @Test func gestureBindingsEndOnTheResetAction() {
        ComponentSnapshot.assert(
            GestureSettingsView(directory: Self.gestureDirectory()),
            named: "settings-gestures",
            height: 1560
        )
    }

    @Test func aboutEndsOnTheVersionItReports() {
        ComponentSnapshot.assert(
            AboutView(version: "1.4", build: "212"),
            named: "settings-about",
            height: 2000
        )
    }

    private static func gestureDirectory() -> URL {
        URL.temporaryDirectory.appending(path: "settings-snapshot-gestures")
    }
}
#endif
