import AnySSHCore

enum MuxHopPlan: Sendable {
    case session(MuxSessionID)
    case tab(SessionSwipeRing.Direction)
}
