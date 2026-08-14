import Foundation

enum LaunchMode: Equatable {
    case live
    case mock(scenario: String)

    static let uiTestFlag = "-UITestMode"
    static let scenarioKey = "ANYSSH_SCENARIO"

    static func current(_ info: ProcessInfo = .processInfo) -> LaunchMode {
        guard info.arguments.contains(uiTestFlag) else { return .live }
        return .mock(scenario: info.environment[scenarioKey] ?? "default")
    }
}
