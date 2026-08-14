import AnySSHCore
import Foundation

@testable import TerminalEmulator

final class VirtualClock: @unchecked Sendable {
    private let lock = NSLock()
    private var instant = ContinuousClock.now

    var now: ContinuousClock.Instant {
        lock.withLock { instant }
    }

    func advance(by duration: Duration) {
        lock.withLock { instant = instant.advanced(by: duration) }
    }
}

actor WaitGate {
    private var parked: [CheckedContinuation<Void, Never>] = []
    private(set) var waits = 0

    func wait(_ duration: Duration) async {
        waits += 1
        await withCheckedContinuation { parked.append($0) }
    }

    func release() {
        let waiting = parked
        parked.removeAll()
        for continuation in waiting {
            continuation.resume()
        }
    }

    func settle() async {
        while parked.isEmpty {
            await Task.yield()
        }
    }
}

actor ResizeRecorder {
    private(set) var sizes: [TerminalSize] = []

    func record(_ size: TerminalSize) {
        sizes.append(size)
    }
}

actor RecordingTransport: TerminalTransport {
    nonisolated let kind = TransportKind.ssh
    nonisolated let capabilities = TransportCapabilities(
        roaming: false,
        serverSideResume: false,
        execChannels: true,
        portForwarding: true
    )

    private(set) var state = TransportState.connected
    private(set) var sizes: [TerminalSize] = []

    func setDelegate(_ delegate: any TerminalTransportDelegate) {}

    func setSink(_ sink: any ByteSink) {}

    func start(size: TerminalSize) async throws {
        sizes.append(size)
    }

    func send(_ bytes: ArraySlice<UInt8>) async throws {}

    func resize(to size: TerminalSize) async throws {
        sizes.append(size)
    }

    func close() async {
        state = .disconnected(.closedByUser)
    }
}
