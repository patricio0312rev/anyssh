import AnySSHCore
import Foundation

public struct HerdrParser: Sendable {
    private let status = HerdrStatusParser()

    public init() {}

    public func clientStatus(from text: String) throws -> HerdrClientStatus {
        try status.clientStatus(from: text)
    }

    public func sessions(from text: String) throws -> [MuxSession] {
        try status.sessions(from: text)
    }

    public func snapshot(from text: String, session: MuxSession) throws -> MuxSnapshot {
        let root = try HerdrJSON.object(text)
        let payload = unwrapSnapshot(root)
        let workspaces = (payload["workspaces"] as? [[String: Any]]) ?? []
        let tabs = (payload["tabs"] as? [[String: Any]]) ?? []
        let panes = (payload["panes"] as? [[String: Any]]) ?? []
        let focusedTab = payload["focused_tab_id"] as? String
        let focusedPane = payload["focused_pane_id"] as? String
        let repoByWorkspace = repositoryRoots(workspaces)

        let groups = tabs.compactMap { tab -> MuxGroup? in
            guard let id = tab["tab_id"] as? String else { return nil }
            let title = firstNonEmpty(tab["label"] as? String) ?? id
            let isActive = HerdrJSON.bool(tab["focused"]) || focusedTab == id
            return MuxGroup(
                id: MuxGroupID(rawValue: id),
                sessionID: session.id,
                title: title,
                isActive: isActive
            )
        }

        let muxPanes = panes.compactMap { pane -> MuxPane? in
            guard let id = pane["pane_id"] as? String,
                let tabID = pane["tab_id"] as? String
            else { return nil }
            let working = firstNonEmpty(
                pane["foreground_cwd"] as? String,
                pane["cwd"] as? String
            )
            let title =
                firstNonEmpty(
                    pane["title"] as? String,
                    pane["label"] as? String,
                    pane["terminal_title_stripped"] as? String,
                    pane["terminal_title"] as? String
                ) ?? id
            let workspaceID = pane["workspace_id"] as? String
            return MuxPane(
                id: MuxPaneID(rawValue: id),
                groupID: MuxGroupID(rawValue: tabID),
                title: title,
                workingDirectory: working,
                isActive: HerdrJSON.bool(pane["focused"]) || focusedPane == id,
                agentStatus: pane["agent_status"] as? String,
                repositoryRoot: workspaceID.flatMap { repoByWorkspace[$0] }
            )
        }

        return MuxSnapshot(session: session, groups: groups, panes: muxPanes)
    }

    public func paneText(from text: String) throws -> String {
        try status.paneText(from: text)
    }

    public func keyBindings(from configText: String) -> MuxKeyBindings {
        status.keyBindings(from: configText)
    }

    private func unwrapSnapshot(_ root: [String: Any]) -> [String: Any] {
        if let result = root["result"] as? [String: Any] {
            if let snapshot = result["snapshot"] as? [String: Any] { return snapshot }
            return result
        }
        if let snapshot = root["snapshot"] as? [String: Any] { return snapshot }
        return root
    }

    private func repositoryRoots(_ workspaces: [[String: Any]]) -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: workspaces.compactMap { workspace in
                guard let id = workspace["workspace_id"] as? String,
                    let worktree = workspace["worktree"] as? [String: Any],
                    let root = worktree["repo_root"] as? String
                else { return nil }
                return (id, root)
            }
        )
    }

    private func firstNonEmpty(_ values: String?...) -> String? {
        for value in values {
            if let value, !value.isEmpty { return value }
        }
        return nil
    }
}
