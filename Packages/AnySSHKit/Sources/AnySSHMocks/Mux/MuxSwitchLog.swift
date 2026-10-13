import AnySSHCore

public actor MuxSwitchLog {
    public private(set) var switches = [MuxSessionSwitch]()

    public init() {}

    public func record(target: MuxSessionID, source: MuxSessionID) {
        switches.append(MuxSessionSwitch(target: target, source: source))
    }
}
