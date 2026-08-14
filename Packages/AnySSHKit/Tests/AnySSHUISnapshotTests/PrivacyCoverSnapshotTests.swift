#if canImport(UIKit)
import SwiftUI
import Testing

@testable import AnySSHUI

@Suite @MainActor struct PrivacyCoverSnapshotTests {
    @Test func theCoverHidesWhateverIsBehindIt() {
        ComponentSnapshot.assert(
            PrivacyCoverView(),
            named: "privacy-cover",
            height: 400
        )
    }
}
#endif
