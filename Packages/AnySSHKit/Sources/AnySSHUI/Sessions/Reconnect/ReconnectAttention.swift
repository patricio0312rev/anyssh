import AnySSHCore

public struct ReconnectAttention: Sendable, Equatable {
    public let isWorkspacePresented: Bool
    public let activeSessionID: SessionID?
    public let engagedSessionIDs: Set<SessionID>
    public let silentSessionIDs: Set<SessionID>

    public static let dismissed = ReconnectAttention(
        isWorkspacePresented: false,
        activeSessionID: nil,
        engagedSessionIDs: [],
        silentSessionIDs: []
    )

    public init(
        isWorkspacePresented: Bool,
        activeSessionID: SessionID?,
        engagedSessionIDs: Set<SessionID>,
        silentSessionIDs: Set<SessionID>
    ) {
        self.isWorkspacePresented = isWorkspacePresented
        self.activeSessionID = activeSessionID
        self.engagedSessionIDs = engagedSessionIDs
        self.silentSessionIDs = silentSessionIDs
    }

    public func scoped(_ records: [SessionRecord], for trigger: ReconnectTrigger) -> [SessionRecord] {
        let claiming = records.filter { claimsDial($0, on: trigger) }
        return claiming.filter { $0.id == activeSessionID }
            + claiming.filter { $0.id != activeSessionID }
    }

    private func claimsDial(_ record: SessionRecord, on trigger: ReconnectTrigger) -> Bool {
        if trigger == .pathChange, silentSessionIDs.contains(record.id) { return true }
        return claimsAttention(record)
    }

    private func claimsAttention(_ record: SessionRecord) -> Bool {
        guard isWorkspacePresented else { return false }
        return record.id == activeSessionID || engagedSessionIDs.contains(record.id)
    }
}
