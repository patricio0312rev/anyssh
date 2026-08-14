public struct MuxSurvivalCopy: Hashable, Sendable {
    public let localSession: String
    public let remoteBootstrap: String?
    public let crossHost: String?

    public init(localSession: String, remoteBootstrap: String?, crossHost: String?) {
        self.localSession = localSession
        self.remoteBootstrap = remoteBootstrap
        self.crossHost = crossHost
    }

    public var cardLines: [String] {
        [localSession, remoteBootstrap, crossHost].compactMap { $0 }
    }

    public static func card(for capabilities: MultiplexerCapabilities) -> MuxSurvivalCopy {
        MuxSurvivalCopy(
            localSession: localLine(capabilities.localSessionSurvival),
            remoteBootstrap: remoteBootstrapLine(capabilities.remoteBootstrapSurvival),
            crossHost: crossHostLine(capabilities.crossHostSurvival)
        )
    }

    public static let provenLocal = "Reattaches on return, like tmux"
    public static let untestedRemoteBootstrap =
        "A server AnySSH started may not survive; the binary warns about this itself"
    public static let untestedCrossHost = "One host, one version measured"
    public static let unsupportedLocal =
        "Backgrounding ends this session. Work continues on the host only if it is inside tmux or herdr."

    private static func localLine(_ confidence: SurvivalConfidence) -> String {
        switch confidence {
        case .proven: provenLocal
        case .unverified: "Local session survival is untested on this host."
        case .unsupported: unsupportedLocal
        }
    }

    private static func remoteBootstrapLine(_ confidence: SurvivalConfidence) -> String? {
        switch confidence {
        case .proven: "A server AnySSH started reattaches on return."
        case .unverified: untestedRemoteBootstrap
        case .unsupported: nil
        }
    }

    private static func crossHostLine(_ confidence: SurvivalConfidence) -> String? {
        switch confidence {
        case .proven: nil
        case .unverified: untestedCrossHost
        case .unsupported: nil
        }
    }
}
