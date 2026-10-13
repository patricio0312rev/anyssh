import AnySSHCore

public actor MuxFocusLog {
    public private(set) var targets = [MuxTarget]()

    public init() {}

    public func record(_ target: MuxTarget) {
        targets.append(target)
    }

    public func focusedGroup(in session: MuxSessionID) -> MuxGroupID? {
        targets.last { $0.session == session && $0.group != nil }?.group
    }
}
