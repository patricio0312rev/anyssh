import AnySSHCore

public enum MuxJumpOutcome: Equatable, Sendable {
    case focused
    case attached
    case focusedElsewhere(MuxSessionID)
    case skipped(MuxSessionID, MuxSkipReason)

    public var skipReason: MuxSkipReason? {
        switch self {
        case .focused, .attached: nil
        case .focusedElsewhere: .boundElsewhere
        case .skipped(_, let reason): reason
        }
    }
}
