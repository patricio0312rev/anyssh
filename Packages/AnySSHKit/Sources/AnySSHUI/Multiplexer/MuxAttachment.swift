import AnySSHCore

public enum MuxAttachment: Equatable, Sendable {
    case attached(MuxSessionID?)
    case detached
    case unknown
}
