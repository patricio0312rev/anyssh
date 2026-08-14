public protocol MultiplexerAdapter: Sendable {
    nonisolated var kind: MultiplexerKind { get }
    nonisolated var capabilities: MultiplexerCapabilities { get }

    func detect() async throws -> MultiplexerInfo
    func listSessions() async throws -> [MuxSession]
    func snapshot(_ session: MuxSession.ID) async throws -> MuxSnapshot
    func readPane(_ pane: MuxPane.ID, lines: Int) async throws -> String
    func keyBindings() async throws -> MuxKeyBindings
    func attachCommand(_ target: MuxTarget) -> String
}
