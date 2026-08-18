import Foundation

public struct SessionTitleContext: Hashable, Sendable {
    public let sessionName: String
    public let agentSessionTitle: String?
    public let agentName: String?
    public let multiplexerName: String?

    public init(
        sessionName: String,
        agentSessionTitle: String? = nil,
        agentName: String? = nil,
        multiplexerName: String? = nil
    ) {
        self.sessionName = sessionName
        self.agentSessionTitle = Self.present(agentSessionTitle)
        self.agentName = Self.present(agentName)
        self.multiplexerName = Self.present(multiplexerName)
    }

    private static func present(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

public enum SessionNavbarTitle {
    public static let separator = " • "
    public static let sample = SessionTitleContext(
        sessionName: "build-box",
        agentSessionTitle: "OC | Mejoras para v0.1.2",
        agentName: "OpenCode",
        multiplexerName: "herdr"
    )

    public static func resolve(_ mode: SessionTitleDisplayMode, context: SessionTitleContext) -> String {
        let session = context.sessionName
        switch mode {
        case .sessionName:
            return session
        case .agentSession:
            return context.agentSessionTitle ?? session
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

    public static func isUsableAgentSessionTitle(_ title: String) -> Bool {
        !genericPaneTitles.contains(title.lowercased())
    }

    private static let genericPaneTitles: Set<String> = [
        "agent", "shell", "nvim", "vim", "zsh", "bash", "fish", "sh",
    ]

    private static func smart(_ context: SessionTitleContext, session: String) -> String {
        if let title = context.agentSessionTitle { return title }
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
