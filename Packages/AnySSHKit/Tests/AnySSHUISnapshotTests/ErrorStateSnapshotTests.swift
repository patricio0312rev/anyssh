#if canImport(UIKit)
import AnySSHCore
import SwiftUI
import Testing

@testable import AnySSHUI

@Suite @MainActor struct ErrorStateSnapshotTests {
    @Test func copyHierarchy() {
        ComponentSnapshot.assert(
            ErrorStateView(state: .transport(.keepaliveTimeout)),
            named: "copyOnly",
            height: 300
        )
    }

    @Test func everyStateCarriesItsOwnIdentifierAndCopy() {
        for state in ErrorState.allCases {
            #expect(state.accessibilityIdentifier == "error.\(state.stateID)")
            #expect(!state.copy.title.isEmpty)
            #expect(!state.copy.body.isEmpty)
            #expect(!state.copy.recoveryLabel.isEmpty)
        }
    }
}
#endif
