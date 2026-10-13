import AnySSHCore

public struct MuxSessionSwitch: Equatable, Sendable {
    public let target: MuxSessionID
    public let source: MuxSessionID

    public init(target: MuxSessionID, source: MuxSessionID) {
        self.target = target
        self.source = source
    }
}
