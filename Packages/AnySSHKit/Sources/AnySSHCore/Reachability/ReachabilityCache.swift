import Foundation

public actor ReachabilityCache {
    public typealias Wait = @Sendable (Duration) async -> Void

    private struct Flight {
        let epoch: UInt64
        let task: Task<Reachability, Never>
    }

    private let probe: any ReachabilityProbe
    private let debounceWindow: Duration
    private let wait: Wait

    private var values: [RemoteID: Reachability] = [:]
    private var inFlight: [RemoteID: Flight] = [:]
    private var tracked: [RemoteID: Remote] = [:]
    private var debounceTask: Task<Void, Never>?
    private var debounceGeneration = 0
    private var epoch: UInt64 = 0

    public init(
        probe: any ReachabilityProbe,
        debounceWindow: Duration = .milliseconds(300),
        wait: @escaping Wait = { try? await Task.sleep(for: $0) }
    ) {
        self.probe = probe
        self.debounceWindow = debounceWindow
        self.wait = wait
    }

    public func status(for id: RemoteID) -> Reachability? {
        values[id]
    }

    public func snapshot() -> [RemoteID: Reachability] {
        values
    }

    public func track(_ remotes: [Remote]) {
        tracked = Dictionary(uniqueKeysWithValues: remotes.map { ($0.id, $0) })
    }

    public func probeNow(_ remote: Remote) async -> Reachability {
        tracked[remote.id] = remote
        while true {
            if let cached = values[remote.id] {
                return cached
            }
            if let flight = inFlight[remote.id] {
                let result = await flight.task.value
                if let cached = values[remote.id] {
                    return cached
                }
                if epoch != flight.epoch {
                    continue
                }
                return result
            }

            let capture = epoch
            let task = Task { await probe.probe(remote) }
            inFlight[remote.id] = Flight(epoch: capture, task: task)
            let result = await task.value
            guard epoch == capture, inFlight[remote.id]?.epoch == capture else {
                continue
            }
            inFlight[remote.id] = nil
            values[remote.id] = result
            return result
        }
    }

    public func invalidate() {
        epoch &+= 1
        values.removeAll(keepingCapacity: true)
        for flight in inFlight.values {
            flight.task.cancel()
        }
        inFlight.removeAll(keepingCapacity: true)
    }

    public func refreshAfterNetworkChange() {
        invalidate()
        debounceGeneration += 1
        let generation = debounceGeneration
        debounceTask?.cancel()
        debounceTask = Task {
            await wait(debounceWindow)
            guard !Task.isCancelled, generation == debounceGeneration else { return }
            await refreshTracked()
        }
    }

    public func settle() async {
        await debounceTask?.value
    }

    public func refreshTracked() async {
        let remotes = Array(tracked.values)
        await withTaskGroup(of: Void.self) { group in
            for remote in remotes {
                group.addTask { _ = await self.probeNow(remote) }
            }
        }
    }
}
