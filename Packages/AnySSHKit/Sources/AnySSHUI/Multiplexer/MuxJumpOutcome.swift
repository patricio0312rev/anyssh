import AnySSHCore

public enum MuxJumpOutcome: Equatable, Sendable {
    case focused
    case attached
    case focusedElsewhere(MuxSessionID)
}
