import AnySSHCore

public actor OutputPump: ByteSink {
    public typealias Drain = @MainActor @Sendable (ArraySlice<UInt8>) async -> Void

    private let deliver: Drain
    private let configuration: PumpConfiguration

    private var pending = PendingBytes()
    private var admissionWaiters: [CheckedContinuation<Void, Never>] = []
    private var wakeup: CheckedContinuation<Void, Never>?
    private var isDraining = false

    public private(set) var metrics = PumpMetrics()

    public init(configuration: PumpConfiguration = .default, deliver: @escaping Drain) {
        self.deliver = deliver
        self.configuration = configuration
    }

    public var pendingByteCount: Int {
        pending.count
    }

    public func ingest(_ bytes: ArraySlice<UInt8>) async {
        while pending.count >= configuration.highWaterMark, !Task.isCancelled {
            await waitForAdmission()
        }
        pending.append(bytes)
        metrics.peakPendingBytes = max(metrics.peakPendingBytes, pending.count)
        wakeDrain()
    }

    public func run() async {
        guard !isDraining else { return }
        isDraining = true
        defer { isDraining = false }

        while !Task.isCancelled {
            guard !pending.isEmpty else {
                await waitForBytes()
                continue
            }
            await coalesce()
            guard !Task.isCancelled else { return }

            let slice = pending.peek(limit: configuration.sliceLimit)
            await deliver(slice)
            pending.commit(slice.count)
            metrics.deliveredSlices += 1
            metrics.deliveredBytes += slice.count
            admitProducers()

            await Task.yield()
        }
    }

    private func coalesce() async {
        var quietTurns = 0
        while pending.count < configuration.sliceLimit, quietTurns < configuration.quiescenceYields {
            let before = pending.count
            await Task.yield()
            guard !Task.isCancelled else { return }
            quietTurns = pending.count > before ? 0 : quietTurns + 1
        }
    }

    private func waitForBytes() async {
        await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                guard pending.isEmpty, !Task.isCancelled else {
                    continuation.resume()
                    return
                }
                wakeup = continuation
            }
        } onCancel: {
            Task { await self.wakeDrain() }
        }
    }

    private func waitForAdmission() async {
        await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                guard pending.count >= configuration.highWaterMark, !Task.isCancelled else {
                    continuation.resume()
                    return
                }
                metrics.suspensions += 1
                admissionWaiters.append(continuation)
            }
        } onCancel: {
            Task { await self.admitProducers(force: true) }
        }
    }

    private func wakeDrain() {
        guard let continuation = wakeup else { return }
        wakeup = nil
        continuation.resume()
    }

    private func admitProducers(force: Bool = false) {
        guard force || pending.count < configuration.highWaterMark else { return }
        let waiters = admissionWaiters
        admissionWaiters.removeAll()
        for waiter in waiters {
            waiter.resume()
        }
    }
}
