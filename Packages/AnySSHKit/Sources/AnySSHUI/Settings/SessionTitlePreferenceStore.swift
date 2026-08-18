import AnySSHCore
import Foundation
import Observation

@MainActor
@Observable
public final class SessionTitlePreferenceStore {
    public static let defaultsKey = "anyssh.session.titleDisplayMode"
    public static let shared = SessionTitlePreferenceStore()

    public var mode: SessionTitleDisplayMode {
        didSet { defaults.set(mode.rawValue, forKey: Self.defaultsKey) }
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.mode = Self.load(from: defaults)
    }

    public static func load(from defaults: UserDefaults = .standard) -> SessionTitleDisplayMode {
        if let stored = defaults.string(forKey: Self.defaultsKey),
            let mode = SessionTitleDisplayMode(rawValue: stored)
        {
            return mode
        }
        return .sessionName
    }
}
