import AnySSHCore
import Foundation

public actor CapabilityCache {
    public static let defaultTTL: TimeInterval = 300

    private struct Entry: Sendable {
        let value: HostCapabilities
        let storedAt: Date
    }

    private let ttl: TimeInterval
    private var entries = [RemoteID: Entry]()

    public init(ttl: TimeInterval = CapabilityCache.defaultTTL) {
        self.ttl = max(0, ttl)
    }

    public func cached(for remoteID: RemoteID, at now: Date = .now) -> HostCapabilities? {
        guard let entry = entries[remoteID], now.timeIntervalSince(entry.storedAt) < ttl else {
            return nil
        }
        return entry.value
    }

    public func capabilities(
        for remoteID: RemoteID,
        using probe: any CapabilityProbe,
        run:
            @escaping @Sendable (_ operation: @escaping @Sendable () async throws -> HostCapabilities)
            async throws -> HostCapabilities,
        at now: Date = .now,
        refresh: Bool = false
    ) async throws -> HostCapabilities {
        if !refresh, let value = cached(for: remoteID, at: now) { return value }
        let value = try await run { try await probe.probe() }
        try Task.checkCancellation()
        entries[remoteID] = Entry(value: value, storedAt: now)
        return value
    }

    public func refresh(
        remoteID: RemoteID,
        using probe: any CapabilityProbe,
        run:
            @escaping @Sendable (_ operation: @escaping @Sendable () async throws -> HostCapabilities)
            async throws -> HostCapabilities,
        at now: Date = .now
    ) async throws -> HostCapabilities {
        try await capabilities(for: remoteID, using: probe, run: run, at: now, refresh: true)
    }

    public func invalidate(remoteID: RemoteID) {
        entries.removeValue(forKey: remoteID)
    }

    public func invalidateOnReconnect(remoteID: RemoteID) {
        invalidate(remoteID: remoteID)
    }

    public func contains(_ remoteID: RemoteID) -> Bool {
        entries[remoteID] != nil
    }
}
