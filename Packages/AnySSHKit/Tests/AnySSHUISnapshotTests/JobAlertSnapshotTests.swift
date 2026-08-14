#if canImport(UIKit)
import Foundation
import SwiftUI
import Testing

@testable import AnySSHUI

@Suite @MainActor struct JobAlertSnapshotTests {
    @Test func everyExplanationSitsUnderTheCardItExplains() {
        ComponentSnapshot.assert(
            JobAlertSettingsView(settings: JobAlertSettings(suppressesSuccess: false)),
            named: "job-alerts-settings",
            height: 900
        )
    }
}
#endif
