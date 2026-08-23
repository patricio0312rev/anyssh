import AnySSHCore

public struct ReconnectAttention: Sendable, Equatable {
    public let isWorkspacePresented: Bool
    public let activeSessionID: SessionID?
    public let engagedSessionIDs: Set<SessionID>

    public static let dismissed = ReconnectAttention(
        isWorkspacePresented: false,
        activeSessionID: nil,
        engagedSessionIDs: []
    )

    public init(
        isWorkspacePresented: Bool,
        activeSessionID: SessionID?,
        engagedSessionIDs: Set<SessionID>
    ) {
        self.isWorkspacePresented = isWorkspacePresented
        self.activeSessionID = activeSessionID
        self.engagedSessionIDs = engagedSessionIDs
    }

    public func scoped(_ records: [SessionRecord]) -> [SessionRecord] {
        guard isWorkspacePresented else { return [] }
        let claiming = records.filter(claimsAttention)
        return claiming.filter { $0.id == activeSessionID }
            + claiming.filter { $0.id != activeSessionID }
    }

    private func claimsAttention(_ record: SessionRecord) -> Bool {
        record.id == activeSessionID || engagedSessionIDs.contains(record.id)
    }
}
