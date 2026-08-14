import Foundation
import Observation

@MainActor
@Observable
public final class LineWrapPreference {
    public static let shared = LineWrapPreference()
    public static let key = "viewer.wrapsLines"

    private let defaults: UserDefaults

    public var wrapsLines: Bool {
        didSet { defaults.set(wrapsLines, forKey: Self.key) }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        wrapsLines = defaults.object(forKey: Self.key) as? Bool ?? true
    }
}
