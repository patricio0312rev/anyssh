import AnySSHCore
import Foundation
import Observation

@MainActor
@Observable
public final class ReachabilityStatusModel {
    public private(set) var presentations: [RemoteID: ReachabilityPresentation] = [:]

    private let cache: ReachabilityCache
    private var pathMonitor: ReachabilityPathMonitor?
    private var known: [Remote] = []

    public init(probe: any ReachabilityProbe) {
        cache = ReachabilityCache(probe: probe)
    }

    public init(cache: ReachabilityCache) {
        self.cache = cache
    }

    public func presentation(for id: RemoteID) -> ReachabilityPresentation {
        presentations[id] ?? .checking
    }

    public func start() {
        guard pathMonitor == nil else { return }
        let monitor = ReachabilityPathMonitor { [weak self] in
            Task { @MainActor in
                await self?.pathDidChange()
            }
        }
        pathMonitor = monitor
        monitor.start()
    }

    public func stop() {
        pathMonitor?.cancel()
        pathMonitor = nil
    }

    public func update(remotes: [Remote]) async {
        known = remotes
        await cache.track(remotes)
        markChecking(remotes.map(\.id))
        let stale = Set(presentations.keys).subtracting(remotes.map(\.id))
        for id in stale {
            presentations.removeValue(forKey: id)
        }
        await refreshAll()
    }

    public func applicationDidBecomeActive() async {
        markChecking(known.map(\.id))
        await cache.refreshAfterNetworkChange()
        await cache.settle()
        await publishSnapshot()
    }

    public func pathDidChange() async {
        markChecking(known.map(\.id))
        await cache.refreshAfterNetworkChange()
        await cache.settle()
        await publishSnapshot()
    }

    public func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            for remote in known {
                group.addTask { await self.probeOne(remote) }
            }
        }
    }

    private func markChecking(_ ids: [RemoteID]) {
        for id in ids {
            presentations[id] = .checking
        }
    }

    private func probeOne(_ remote: Remote) async {
        let result = await cache.probeNow(remote)
        guard known.contains(where: { $0.id == remote.id }) else { return }
        presentations[remote.id] = ReachabilityPresentation(result)
    }

    private func publishSnapshot() async {
        let snapshot = await cache.snapshot()
        for remote in known {
            if let value = snapshot[remote.id] {
                presentations[remote.id] = ReachabilityPresentation(value)
            } else {
                presentations[remote.id] = .checking
            }
        }
    }
}
