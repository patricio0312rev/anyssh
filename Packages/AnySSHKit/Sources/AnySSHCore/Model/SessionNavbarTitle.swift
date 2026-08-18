public struct SessionTitleContext: Hashable, Sendable {
    public let sessionName: String
    public let agentName: String?
    public let multiplexerName: String?

    public init(sessionName: String, agentName: String? = nil, multiplexerName: String? = nil) {
        self.sessionName = sessionName
        self.agentName = agentName
        self.multiplexerName = multiplexerName
    }
}

public enum SessionNavbarTitle {
    public static let separator = " • "
    public static let sample = SessionTitleContext(
        sessionName: "build-box",
        agentName: "Codex",
        multiplexerName: "herdr"
    )

    public static func resolve(_ mode: SessionTitleDisplayMode, context: SessionTitleContext) -> String {
        let session = context.sessionName
        switch mode {
        case .sessionName:
            return session
        case .activeAgent:
            return context.agentName ?? session
        case .multiplexer:
            return context.multiplexerName ?? session
        case .smart:
            return smart(context, session: session)
        }
    }

    public static func preview(for mode: SessionTitleDisplayMode) -> String {
        resolve(mode, context: sample)
    }

    private static func smart(_ context: SessionTitleContext, session: String) -> String {
        switch (context.agentName, context.multiplexerName) {
        case (let agent?, let mux?) where agent.compare(mux, options: .caseInsensitive) == .orderedSame:
            return agent
        case (let agent?, let mux?):
            return agent + separator + mux
        case (let agent?, nil):
            return agent
        case (nil, let mux?):
            return mux
        case (nil, nil):
            return session
        }
    }
}
