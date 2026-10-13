import AnySSHCore

public enum MuxSkipReason: Equatable, Sendable {
    case detached
    case unidentified
    case unreadable
    case boundElsewhere
    case timedOut
    case refused(ErrorState)
}
