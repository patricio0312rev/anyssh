import AnySSHCore
import Foundation

@testable import SSHTransport

actor ShellSink: ByteSink {
    private(set) var bytes: [UInt8] = []
    private(set) var chunks = 0

    var text: String {
        String(decoding: bytes, as: UTF8.self)
    }

    func ingest(_ slice: ArraySlice<UInt8>) async {
        bytes.append(contentsOf: slice)
        chunks += 1
    }

    func clear() {
        bytes.removeAll()
    }

    func waitFor(_ marker: String, ceiling: Duration = .seconds(60)) async -> Bool {
        let limit = ContinuousClock.now + ceiling
        while !text.contains(marker) {
            guard ContinuousClock.now < limit else { return false }
            await Task.yield()
        }
        return true
    }
}

actor SaturatingSink: ByteSink {
    private let highWaterMark: Int
    private let tailLimit = 4096
    private var waiter: CheckedContinuation<Void, Never>?
    private var isOpen = false
    private var tail: [UInt8] = []

    private(set) var acceptedBytes = 0
    private(set) var suspensions = 0
    private(set) var chunks = 0

    init(highWaterMark: Int = 64 * 1024) {
        self.highWaterMark = highWaterMark
    }

    var isSuspended: Bool {
        waiter != nil
    }

    var text: String {
        String(decoding: tail, as: UTF8.self)
    }

    func ingest(_ slice: ArraySlice<UInt8>) async {
        while acceptedBytes >= highWaterMark, !isOpen {
            suspensions += 1
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                waiter = continuation
            }
        }
        acceptedBytes += slice.count
        chunks += 1
        tail.append(contentsOf: slice)
        if tail.count > tailLimit {
            tail.removeFirst(tail.count - tailLimit)
        }
    }

    func release() {
        isOpen = true
        waiter?.resume()
        waiter = nil
    }

    func waitUntilSuspended(ceiling: Duration = .seconds(60)) async -> Bool {
        let limit = ContinuousClock.now + ceiling
        while !isSuspended {
            guard ContinuousClock.now < limit else { return false }
            await Task.yield()
        }
        return true
    }

    func waitFor(_ marker: String, ceiling: Duration = .seconds(60)) async -> Bool {
        let limit = ContinuousClock.now + ceiling
        while !text.contains(marker) {
            guard ContinuousClock.now < limit else { return false }
            await Task.yield()
        }
        return true
    }
}

final class DisplayDelegate: TerminalTransportDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private let verdict: HostKeyVerdict
    private var reported: [TransportState] = []

    init(_ verdict: HostKeyVerdict = .accept(remember: true)) {
        self.verdict = verdict
    }

    var states: [TransportState] {
        lock.withLock { reported }
    }

    func transport(
        _ transport: any TerminalTransport,
        verify key: HostKey,
        status: KnownHostStatus
    ) async -> HostKeyVerdict {
        verdict
    }

    func transport(
        _ transport: any TerminalTransport,
        answer round: AuthPromptRound
    ) async -> AuthPromptAnswer {
        .cancelled
    }

    func transport(_ transport: any TerminalTransport, didChange state: TransportState) async {
        lock.withLock { reported.append(state) }
    }
}
