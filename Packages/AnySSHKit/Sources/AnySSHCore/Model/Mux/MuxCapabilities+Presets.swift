extension MultiplexerCapabilities {
    public static let tmux = MultiplexerCapabilities(
        structuredOutput: false,
        agentStatus: false,
        worktreeMetadata: false,
        paneRead: true,
        eventStream: false,
        localSessionSurvival: .proven,
        remoteBootstrapSurvival: .unsupported,
        crossHostSurvival: .proven
    )

    public static let herdr = MultiplexerCapabilities(
        structuredOutput: true,
        agentStatus: true,
        worktreeMetadata: true,
        paneRead: true,
        eventStream: false,
        localSessionSurvival: .proven,
        remoteBootstrapSurvival: .unverified,
        crossHostSurvival: .unverified
    )

    public static let none = MultiplexerCapabilities(
        structuredOutput: false,
        agentStatus: false,
        worktreeMetadata: false,
        paneRead: false,
        eventStream: false,
        localSessionSurvival: .unsupported,
        remoteBootstrapSurvival: .unsupported,
        crossHostSurvival: .unsupported
    )
}
