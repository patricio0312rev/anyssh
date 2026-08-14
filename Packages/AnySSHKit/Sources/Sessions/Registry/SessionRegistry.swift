import AnySSHCore
import Foundation

public struct SessionRegistry: Sendable, Equatable {
    public private(set) var sessions: [SessionRecord]

    public init(_ sessions: [SessionRecord] = []) {
        var seen = Set<SessionID>()
        self.sessions = sessions.filter { seen.insert($0.id).inserted }
    }

    public var count: Int {
        sessions.count
    }

    public var isEmpty: Bool {
        sessions.isEmpty
    }

    public var ids: [SessionID] {
        sessions.map(\.id)
    }

    public var titles: [String] {
        sessions.map(\.title)
    }

    public subscript(id: SessionID) -> SessionRecord? {
        sessions.first { $0.id == id }
    }

    public func index(of id: SessionID) -> Int? {
        sessions.firstIndex { $0.id == id }
    }

    public func sessions(on connectionID: ConnectionID) -> [SessionRecord] {
        sessions.filter { $0.connectionID == connectionID }
    }

    public var mostRecentlyActive: SessionRecord? {
        sessions.max { $0.lastActiveAt < $1.lastActiveAt }
    }

    @discardableResult
    public mutating func open(_ record: SessionRecord) -> SessionRecord {
        if let existing = self[record.id] { return existing }
        var opened = record
        opened.title = SessionTitle.unique(record.title, among: titles)
        sessions.append(opened)
        return opened
    }

    @discardableResult
    public mutating func rename(_ id: SessionID, to title: String) -> Bool {
        guard let index = index(of: id), let sanitized = SessionTitle.sanitized(title) else {
            return false
        }
        sessions[index].title = sanitized
        return true
    }

    @discardableResult
    public mutating func close(_ id: SessionID) -> SessionRecord? {
        guard let index = index(of: id) else { return nil }
        return sessions.remove(at: index)
    }

    public mutating func move(_ id: SessionID, to index: Int) {
        guard let current = self.index(of: id), sessions.count > 1 else { return }
        let target = min(max(0, index), sessions.count - 1)
        guard target != current else { return }
        let record = sessions.remove(at: current)
        sessions.insert(record, at: target)
    }

    public mutating func update(_ id: SessionID, state: TransportState, at date: Date) {
        guard let index = index(of: id) else { return }
        sessions[index].state = state
        switch state {
        case .reconnecting(let attempt):
            sessions[index].reconnectAttempts = attempt
        case .connected:
            sessions[index].reconnectAttempts = 0
            sessions[index].lastActiveAt = date
        case .disconnected(.closedByUser):
            sessions[index].reconnectAttempts = 0
        default:
            break
        }
    }

    public mutating func touch(_ id: SessionID, at date: Date) {
        guard let index = index(of: id) else { return }
        sessions[index].lastActiveAt = date
    }

    public mutating func setWorkspace(_ workspace: WorkspaceLocation?, for id: SessionID) {
        guard let index = index(of: id) else { return }
        sessions[index].workspace = workspace
    }

    public func reconnectState(for id: SessionID) -> SessionReconnectState? {
        guard let record = self[id] else { return nil }
        return SessionReconnectState.derived(from: record.state, capabilities: record.capabilities)
    }
}
