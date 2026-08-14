import Synchronization

public final class ControlChannelLedger: Sendable {
    private struct State {
        var open = Set<Int>()
        var issued = 0
        var peak = 0
        var closes = 0
    }

    private let state = Mutex(State())

    public init() {}

    public var openCount: Int { state.withLock { $0.open.count } }
    public var peakOpenCount: Int { state.withLock { $0.peak } }
    public var closeCount: Int { state.withLock { $0.closes } }

    func opened() -> Int {
        state.withLock { state in
            state.issued += 1
            state.open.insert(state.issued)
            state.peak = max(state.peak, state.open.count)
            return state.issued
        }
    }

    func closed(_ channel: Int) {
        state.withLock { state in
            guard state.open.remove(channel) != nil else { return }
            state.closes += 1
        }
    }
}
