import AnySSHCore
import Foundation

public actor MockRemoteConnection: RemoteConnection {
    private struct Work: Sendable {
        let cancel: @Sendable () -> Void
        let drain: @Sendable () async -> Void
    }

    public nonisolated let connectionID: ConnectionID

    public private(set) var displayState = TransportState.idle
    public private(set) var controlState = TransportState.idle
    public var clientPort: Int? { nil }
    public private(set) var openChannelCount = 0
    public private(set) var peakChannelCount = 0
    public private(set) var completedRuns = 0
    public private(set) var cancellations = 0
    public private(set) var lastCancellationReason: DisconnectReason?
    public private(set) var displayWrites: [[UInt8]] = []
    public private(set) var attachCount = 0

    public var script: MockControlScript
    public let displayScript: MockDisplayScript
    private var work = [Int: Work]()
    private var nextWorkID = 0
    private var isClosed = false

    public init(
        connectionID: ConnectionID = ConnectionID(rawValue: "mock"),
        script: MockControlScript = MockControlScript(),
        displayScript: MockDisplayScript = MockDisplayScript()
    ) {
        self.connectionID = connectionID
        self.script = script
        self.displayScript = displayScript
    }

    public func setScript(_ script: MockControlScript) {
        self.script = script
    }

    public func setDisplayState(_ state: TransportState) {
        displayState = state
    }

    public func attachDisplay(sink: any ByteSink, size: TerminalSize) async throws {
        attachCount += 1
        displayState = .connected
        let steps = displayScript.steps
        guard !steps.isEmpty else { return }
        Task.detached {
            for step in steps {
                try? await Task.sleep(for: step.delay)
                await sink.ingest(ArraySlice(step.bytes))
            }
        }
    }

    public func setDisplayDelegate(_ delegate: any TerminalTransportDelegate) async {
        _ = delegate
    }

    public func sendDisplay(_ bytes: ArraySlice<UInt8>) async throws {
        guard !isClosed else { throw ErrorState.transport(.connectionRefused) }
        displayWrites.append(Array(bytes))
    }

    public func send(_ bytes: ArraySlice<UInt8>) async throws {
        try await sendDisplay(bytes)
    }

    public func resizeDisplay(to size: TerminalSize) async throws {
        _ = size
        guard !isClosed else { throw ErrorState.transport(.connectionRefused) }
    }

    public func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        guard !isClosed else { throw ErrorState.transport(.connectionRefused) }
        controlState = .connected

        let id = nextWorkID
        nextWorkID += 1
        let task = Task { try await self.perform(batch) }
        work[id] = Work(cancel: { task.cancel() }, drain: { _ = await task.result })
        defer { work[id] = nil }

        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    public func cancelAll(reason: DisconnectReason = .cancelledBySwitch) async {
        cancellations += 1
        lastCancellationReason = reason
        guard !work.isEmpty else { return }

        let pending = Array(work.values)
        work.removeAll()
        for item in pending { item.cancel() }
        for item in pending { await item.drain() }
    }

    public func close(reason: DisconnectReason = .closedByUser) async {
        isClosed = true
        await cancelAll(reason: reason)
        displayState = .disconnected(reason)
        controlState = .disconnected(reason)
    }

    public var inFlightControlCount: Int {
        work.count
    }

    private func perform(_ batch: RemoteBatch) async throws -> BatchResponse {
        let response = try script.response(to: batch)
        openChannel()
        do {
            try await Task.sleep(for: script.duration)
        } catch {
            await Task { [latency = script.cancelLatency] in
                try? await Task.sleep(for: latency)
            }.value
            closeChannel()
            throw ErrorState.transport(.cancelledBySwitch)
        }
        closeChannel()
        completedRuns += 1
        return response
    }

    private func openChannel() {
        openChannelCount += 1
        peakChannelCount = max(peakChannelCount, openChannelCount)
    }

    private func closeChannel() {
        openChannelCount = max(0, openChannelCount - 1)
    }
}
