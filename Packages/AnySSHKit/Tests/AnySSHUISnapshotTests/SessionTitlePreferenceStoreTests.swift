import Foundation
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionTitlePreferenceStoreTests {
    @Test func aMissingValueIsTheSessionName() {
        let store = SessionTitlePreferenceStore(defaults: suite("missing"))
        #expect(store.mode == .sessionName)
    }

    @Test func aStoredModeReloads() {
        let defaults = suite("stored")
        let first = SessionTitlePreferenceStore(defaults: defaults)
        first.mode = .smart
        let reloaded = SessionTitlePreferenceStore(defaults: defaults)
        #expect(reloaded.mode == .smart)
    }

    private func suite(_ name: String) -> UserDefaults {
        let suiteName = "session-title-\(name)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
