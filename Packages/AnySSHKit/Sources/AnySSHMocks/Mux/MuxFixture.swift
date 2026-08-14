import AnySSHCore
import Foundation

public enum MuxFixture: String, CaseIterable, Sendable {
    case tmuxMain = "tmux-main"
    case herdrDefault = "herdr-default"
    case herdrProtocolMismatch = "herdr-protocol-mismatch"
    case absent = "absent"

    public var deepLink: URL {
        var components = URLComponents()
        components.scheme = "anyssh"
        components.host = "mux"
        components.path = "/\(rawValue)"
        return components.url ?? URL(filePath: rawValue)
    }

    public var kind: MultiplexerKind {
        switch self {
        case .tmuxMain: .tmux
        case .herdrDefault, .herdrProtocolMismatch: .herdr
        case .absent: .none
        }
    }

    public var capabilities: MultiplexerCapabilities {
        switch kind {
        case .tmux: .tmux
        case .herdr: .herdr
        case .none: .none
        }
    }
}
