import AnySSHCore

public typealias MultiplexerKind = AnySSHCore.MultiplexerKind

public struct MultiplexerBinding: Hashable, Sendable {
    public let sessionID: SessionID
    public let kind: MultiplexerKind

    public init(session: SessionRecord, kind: MultiplexerKind) {
        self.sessionID = session.id
        self.kind = kind
    }

    public init(sessionID: SessionID, kind: MultiplexerKind) {
        self.sessionID = sessionID
        self.kind = kind
    }
}
