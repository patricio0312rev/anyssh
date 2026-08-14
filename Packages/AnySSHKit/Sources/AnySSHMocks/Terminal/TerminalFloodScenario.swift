import Foundation

public enum TerminalMockScenario: String, CaseIterable, Sendable {
    case terminalFlood
}

public enum TerminalFloodTrigger {
    public static let scheme = "anyssh"
    public static let host = "terminal"
    public static let path = "/flood"

    public static let link = "\(scheme)://\(host)\(path)"

    public static func url() -> URL? {
        URL(string: link)
    }

    public static func scenario(from url: URL) -> TerminalMockScenario? {
        guard url.scheme == scheme, url.host() == host, url.path() == path else { return nil }
        return .terminalFlood
    }
}
