import AnySSHCore
import Foundation

public enum ErrorStateTrigger {
    public static let scheme = "anyssh"
    public static let host = "error"

    public static var all: [(state: ErrorState, link: String)] {
        ErrorState.allCases.map { ($0, link(for: $0)) }
    }

    public static func link(for state: ErrorState) -> String {
        "\(scheme)://\(host)/\(state.stateID)"
    }

    public static func url(for state: ErrorState) -> URL? {
        URL(string: link(for: state))
    }

    public static func state(from url: URL) -> ErrorState? {
        guard url.scheme == scheme, url.host() == host else { return nil }
        return ErrorState(stateID: String(url.path().trimmingPrefix("/")))
    }
}
