import AnySSHCore

public enum GitParserError: Error, Sendable, Equatable {
    case state(ErrorState)
    case malformed(String)
}
