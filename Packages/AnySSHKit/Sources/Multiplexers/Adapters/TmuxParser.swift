import AnySSHCore
import Foundation

public enum TmuxParseError: Error, Hashable, Sendable {
    case emptyVersion
    case malformedRow(String)
    case missingSession(String)
}

public struct TmuxParser: Sendable {
    public init() {}

    public func version(from text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TmuxParseError.emptyVersion }
        if trimmed.hasPrefix("tmux ") {
            return String(trimmed.dropFirst("tmux ".count))
        }
        return trimmed
    }

    public func sessions(from text: String) throws -> [MuxSession] {
        try nonEmptyLines(text).map(session(from:))
    }

    public func snapshot(
        sessionID: MuxSessionID,
        sessionsText: String,
        windowsText: String,
        panesText: String
    ) throws -> MuxSnapshot {
        let sessions = try sessions(from: sessionsText)
        guard
            let session = sessions.first(where: { $0.id == sessionID })
                ?? sessions.first(where: { $0.name == sessionID.rawValue })
        else {
            throw TmuxParseError.missingSession(sessionID.rawValue)
        }
        let groups = try nonEmptyLines(windowsText).compactMap { line -> MuxGroup? in
            let group = try group(from: line)
            return group.sessionID == session.id ? group : nil
        }
        let groupIDs = Set(groups.map(\.id))
        let panes = try nonEmptyLines(panesText).compactMap { line -> MuxPane? in
            let pane = try pane(from: line)
            return groupIDs.contains(pane.groupID) ? pane : nil
        }
        return MuxSnapshot(session: session, groups: groups, panes: panes)
    }

    public func prefix(from text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func session(from line: String) throws -> MuxSession {
        let columns = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard columns.count >= 3 else { throw TmuxParseError.malformedRow(line) }
        return MuxSession(
            id: MuxSessionID(rawValue: columns[0]),
            name: columns[1],
            isAttached: columns[2] == "1"
        )
    }

    private func group(from line: String) throws -> MuxGroup {
        let columns = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard columns.count >= 4 else { throw TmuxParseError.malformedRow(line) }
        return MuxGroup(
            id: MuxGroupID(rawValue: columns[1]),
            sessionID: MuxSessionID(rawValue: columns[0]),
            title: columns[2],
            isActive: columns[3] == "1"
        )
    }

    private func pane(from line: String) throws -> MuxPane {
        let columns = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard columns.count >= 6 else { throw TmuxParseError.malformedRow(line) }
        let path = columns[4]
        return MuxPane(
            id: MuxPaneID(rawValue: columns[2]),
            groupID: MuxGroupID(rawValue: columns[1]),
            title: columns[3],
            workingDirectory: path.isEmpty ? nil : path,
            isActive: columns[5] == "1",
            agentStatus: nil,
            repositoryRoot: nil
        )
    }

    private func nonEmptyLines(_ text: String) -> [String] {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
