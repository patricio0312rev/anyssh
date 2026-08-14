import Foundation
import Observation

@MainActor
@Observable
public final class JobAlertSettings {
    public static let quietKey = "anyssh.jobAlerts.quietSuccess"

    public var suppressesSuccess: Bool {
        didSet { UserDefaults.standard.set(suppressesSuccess, forKey: Self.quietKey) }
    }

    public init(suppressesSuccess: Bool? = nil) {
        let stored = UserDefaults.standard.object(forKey: Self.quietKey) as? Bool
        self.suppressesSuccess = suppressesSuccess ?? stored ?? false
    }
}
