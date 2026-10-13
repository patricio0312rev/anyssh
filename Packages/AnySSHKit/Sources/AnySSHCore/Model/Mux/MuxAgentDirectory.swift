import Foundation

public enum MuxAgentDirectory {
    public static func entries(in snapshot: MuxSnapshot) -> [MuxAgentEntry] {
        let detector = AgentKindDetector()
        return snapshot.panes.compactMap { pane in
            entry(for: pane, in: snapshot, detector: detector)
        }
    }

    private static func entry(
        for pane: MuxPane,
        in snapshot: MuxSnapshot,
        detector: AgentKindDetector
    ) -> MuxAgentEntry? {
        let agent = usable(pane.agent, for: pane)
        let kind = detector.detect(signals: [agent, pane.title, pane.terminalTitle].compactMap { $0 })
        guard agent != nil || kind != nil else { return nil }
        let title = title(for: pane) ?? kind?.name ?? agent ?? pane.id.rawValue
        let group = snapshot.groups.first { $0.id == pane.groupID }
        return MuxAgentEntry(
            id: pane.id,
            sessionID: snapshot.session.id,
            groupID: pane.groupID,
            title: title,
            detail: detail(for: pane, title: title),
            tabTitle: group.flatMap { usable($0.title, for: pane) },
            kind: kind,
            status: pane.agentStatus,
            isActive: pane.isActive && group?.isActive != false
        )
    }

    private static func title(for pane: MuxPane) -> String? {
        [pane.agentName, pane.title, pane.terminalTitle]
            .lazy
            .compactMap { usable($0, for: pane) }
            .first { SessionNavbarTitle.isUsableAgentSessionTitle($0) }
    }

    private static func detail(for pane: MuxPane, title: String) -> String? {
        guard let terminal = usable(pane.terminalTitle, for: pane),
            terminal != title,
            SessionNavbarTitle.isUsableAgentSessionTitle(terminal)
        else { return nil }
        return terminal
    }

    private static func usable(_ value: String?, for pane: MuxPane) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
            !trimmed.isEmpty,
            trimmed != pane.id.rawValue,
            trimmed != pane.groupID.rawValue
        else { return nil }
        return trimmed
    }
}
