import Foundation
import Testing

@testable import AnySSHCore

@Suite struct ReachabilityCacheTests {
    @Test func probeNowCachesPerRemote() async {
        let probe = CountingProbe(result: .reachable)
        let cache = ReachabilityCache(probe: probe, debounceWindow: .milliseconds(10)) {
            try? await Task.sleep(for: $0)
        }
        let remote = sample(id: "a")

        let first = await cache.probeNow(remote)
        let second = await cache.probeNow(remote)

        #expect(first == .reachable)
        #expect(second == .reachable)
        #expect(await probe.count == 1)
        #expect(await cache.status(for: remote.id) == .reachable)
    }

    @Test func invalidateClearsCachedValues() async {
        let probe = CountingProbe(result: .reachable)
        let cache = ReachabilityCache(probe: probe)
        let remote = sample(id: "b")
        _ = await cache.probeNow(remote)
        await cache.invalidate()
        #expect(await cache.status(for: remote.id) == nil)
    }

    @Test func pathChangeDebouncesOneRefresh() async {
        let probe = CountingProbe(result: .unreachable)
        let waits = WaitCounter()
        let cache = ReachabilityCache(
            probe: probe,
            debounceWindow: .milliseconds(20)
        ) { duration in
            await waits.increment()
            try? await Task.sleep(for: duration)
        }
        let remote = sample(id: "c")
        await cache.track([remote])

        await cache.refreshAfterNetworkChange()
        await cache.refreshAfterNetworkChange()
        await cache.settle()

        #expect(await waits.count == 2)
        #expect(await probe.count == 1)
        #expect(await cache.status(for: remote.id) == .unreachable)
    }

    @Test func invalidateDropsInFlightResults() async {
        let probe = HoldingProbe(result: .reachable)
        let cache = ReachabilityCache(probe: probe)
        let remote = sample(id: "d")

        let probing = Task { await cache.probeNow(remote) }
        await probe.waitUntilStarted(count: 1)
        await cache.invalidate()
        await probe.waitUntilStarted(count: 2)
        await probe.releaseAll()
        let result = await probing.value

        #expect(result == .reachable)
        #expect(await probe.starts == 2)
        #expect(await cache.status(for: remote.id) == .reachable)
    }

    private func sample(id: String) -> Remote {
        Remote(
            id: RemoteID(rawValue: id),
            name: id,
            host: "127.0.0.1",
            port: 9,
            username: "probe"
        )
    }
}

private actor CountingProbe: ReachabilityProbe {
    private let result: Reachability
    private(set) var count = 0

    init(result: Reachability) {
        self.result = result
    }

    func probe(_ remote: Remote) async -> Reachability {
        count += 1
        return result
    }
}

private actor HoldingProbe: ReachabilityProbe {
    private let result: Reachability
    private(set) var starts = 0
    private var open = false

    init(result: Reachability) {
        self.result = result
    }

    func probe(_ remote: Remote) async -> Reachability {
        starts += 1
        while !open {
            if Task.isCancelled {
                return .unknown
            }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return result
    }

    func waitUntilStarted(count: Int) async {
        while starts < count {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    func releaseAll() {
        open = true
    }
}

private actor WaitCounter {
    private(set) var count = 0

    func increment() {
        count += 1
    }
}
