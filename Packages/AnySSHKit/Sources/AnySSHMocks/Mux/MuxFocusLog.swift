import AnySSHCore

public actor MuxFocusLog {
    public private(set) var targets = [MuxTarget]()

    public init() {}

    public func record(_ target: MuxTarget) {
        targets.append(target)
    }
}
