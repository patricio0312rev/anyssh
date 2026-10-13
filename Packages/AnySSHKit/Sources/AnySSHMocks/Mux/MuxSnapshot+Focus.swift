import AnySSHCore

extension MuxSnapshot {
    public func focusing(_ focused: MuxGroupID?) -> MuxSnapshot {
        guard let focused, groups.contains(where: { $0.id == focused }) else { return self }
        let marked = groups.map { group in
            MuxGroup(
                id: group.id,
                sessionID: group.sessionID,
                title: group.title,
                isActive: group.id == focused
            )
        }
        return MuxSnapshot(session: session, groups: marked, panes: panes)
    }
}
