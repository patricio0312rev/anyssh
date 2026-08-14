import AnySSHCore
import AnySSHMocks
import Foundation

enum DeepLinkRouter {
    static let scheme = ErrorStateTrigger.scheme
    static let scenarioHost = "scenario"

    static func scenario(for url: URL) -> LaunchScenario? {
        guard url.scheme == scheme else { return nil }
        if let state = ErrorStateTrigger.state(from: url) {
            return .errorState(state)
        }
        guard url.host() == scenarioHost else { return nil }
        let name = String(url.path().trimmingPrefix("/"))
        return name.isEmpty ? nil : LaunchScenario(name)
    }
}
