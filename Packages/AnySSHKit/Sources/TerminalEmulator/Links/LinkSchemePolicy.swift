import AnySSHCore
import Foundation

public enum LinkOpenOutcome: Equatable, Sendable {
    case open
    case refused(ErrorState)
}

public enum LinkSchemePolicy {
    public static let openableSchemes = ["http", "https"]

    public static func outcome(for url: URL) -> LinkOpenOutcome {
        guard let scheme = url.scheme?.lowercased(), openableSchemes.contains(scheme) else {
            return .refused(ErrorState.link(.schemeRefused))
        }
        return .open
    }
}
