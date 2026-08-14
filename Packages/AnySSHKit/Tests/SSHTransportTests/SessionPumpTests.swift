import AnySSHCore
import CSSH
import Foundation
import Testing

@testable import SSHTransport

@Suite struct SessionPumpTests {
    @Test func pumpsEveryChunkIntoTheSinkAndStopsAtEndOfStream() async throws {
        let reader = ScriptedReader([
            .again, .bytes(Array("ANYSSH".utf8)), .again, .bytes(Array("-READY".utf8)), .end,
        ])
        let sink = RecordingSink()
        let session = SSHSession(target: SessionTarget(host: "127.0.0.1", port: 22))

        try await session.pump(from: reader.reader, into: sink)

        #expect(sink.chunks.map { String(decoding: $0, as: UTF8.self) } == ["ANYSSH", "-READY"])
        #expect(reader.callCount == 5)
    }

    @Test func theLoopSuspendsWhileTheSinkIsSaturated() async throws {
        let reader = ScriptedReader([.bytes([0x41]), .bytes([0x42]), .end])
        let sink = RecordingSink()
        sink.holdFirstIngest = true
        let session = SSHSession(target: SessionTarget(host: "127.0.0.1", port: 22))

        let pump = Task { try await session.pump(from: reader.reader, into: sink) }
        try #require(await sink.waitUntilHolding(), "the pump never reached the sink")
        for _ in 0..<100 { await Task.yield() }

        #expect(reader.callCount == 1)
        sink.release()
        try await pump.value

        #expect(sink.chunks == [[0x41], [0x42]])
    }

    @Test func aReadErrorEndsTheLoopWithItsErrorState() async {
        let reader = ScriptedReader([.failure(LIBSSH2_ERROR_SOCKET_RECV)])
        let session = SSHSession(target: SessionTarget(host: "127.0.0.1", port: 22))

        await #expect(throws: TransportFailure.connectionLost(code: LIBSSH2_ERROR_SOCKET_RECV)) {
            try await session.pump(from: reader.reader, into: RecordingSink())
        }
    }
}

private enum ReadStep {
    case again
    case bytes([UInt8])
    case end
    case failure(Int32)
}

private final class ScriptedReader: @unchecked Sendable {
    private let lock = NSLock()
    private var steps: [ReadStep]
    private var calls = 0

    init(_ steps: [ReadStep]) {
        self.steps = steps
    }

    var callCount: Int {
        lock.withLock { calls }
    }

    var reader: SessionByteReader {
        SessionByteReader { [self] buffer in next(into: buffer) }
    }

    private func next(into buffer: UnsafeMutableRawBufferPointer) -> Int {
        lock.withLock {
            calls += 1
            guard !steps.isEmpty else { return 0 }
            switch steps.removeFirst() {
            case .again: return Int(LIBSSH2_ERROR_EAGAIN)
            case .end: return 0
            case .failure(let code): return Int(code)
            case .bytes(let bytes):
                for (offset, byte) in bytes.enumerated() { buffer[offset] = byte }
                return bytes.count
            }
        }
    }
}

private final class RecordingSink: ByteSink, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded = [[UInt8]]()
    private var held: CheckedContinuation<Void, Never>?
    private var holding = false

    var holdFirstIngest = false

    var chunks: [[UInt8]] {
        lock.withLock { recorded }
    }

    var isHolding: Bool {
        lock.withLock { holding }
    }

    func waitUntilHolding(withinYields ceiling: Int = 10_000) async -> Bool {
        for _ in 0..<ceiling {
            if isHolding { return true }
            await Task.yield()
        }
        return isHolding
    }

    func ingest(_ bytes: ArraySlice<UInt8>) async {
        let shouldHold = lock.withLock {
            let hold = holdFirstIngest
            holdFirstIngest = false
            holding = hold
            return hold
        }
        if shouldHold {
            await withCheckedContinuation { continuation in
                lock.withLock { held = continuation }
            }
        }
        lock.withLock { recorded.append(Array(bytes)) }
    }

    func release() {
        let continuation = lock.withLock {
            holding = false
            let waiting = held
            held = nil
            return waiting
        }
        continuation?.resume()
    }
}
