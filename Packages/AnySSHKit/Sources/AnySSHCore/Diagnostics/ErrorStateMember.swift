public protocol ErrorStateMember: RawRepresentable, CaseIterable, Hashable, Sendable
where RawValue == String {
    static var group: ErrorStateGroup { get }

    var copy: ErrorStateCopy { get }

    var owningPhase: Int { get }
}

extension ErrorStateMember {
    public var group: ErrorStateGroup { Self.group }

    public var stateID: String { "\(Self.group.rawValue).\(rawValue)" }
}
