import Foundation
import Testing

@testable import TerminalEmulator

@Suite(.enabled(if: ProcessInfo.processInfo.environment["PUMP_BENCH"] == "1"))
struct PumpThroughputTests {
    @Test func floodThroughput() async {
        for readSize in [1024, 16 * 1024, 64 * 1024] {
            await measureFlood(readSize: readSize)
        }
    }

    @Test func coalescingProfile() async {
        let reads = 700
        let size = 1_500
        let target = RecordingTarget()
        let pump = await target.pump()
        let drain = Task { await pump.run() }
        let chunk = [UInt8](repeating: 0x2E, count: size)
        for _ in 0..<reads {
            await pump.ingest(chunk[...])
        }
        await waitUntil { await pump.pendingByteCount == 0 }
        drain.cancel()
        await drain.value

        let metrics = await pump.metrics
        print(
            "pump coalescing: \(reads) reads of \(size)B became \(metrics.deliveredSlices) drains,"
                + " \(metrics.deliveredBytes / metrics.deliveredSlices) bytes per hop,"
                + " \(metrics.suspensions) suspensions,"
                + " peak pending \(metrics.peakPendingBytes)B"
        )
        #expect(metrics.deliveredBytes == reads * size)
    }

    @Test func idleEchoLatency() async {
        let iterations = 500
        let target = TimestampingTarget()
        let pump = await target.pump()
        let drain = Task { await pump.run() }
        let keystroke = [UInt8]("x".utf8)

        var samples: [Duration] = []
        for index in 0..<iterations {
            let sent = ContinuousClock.now
            await pump.ingest(keystroke[...])
            await waitUntil { await target.receivedAt.count > index }
            samples.append(await target.receivedAt[index] - sent)
        }
        drain.cancel()
        await drain.value

        samples.sort()
        print(
            "pump echo latency over \(iterations) single-byte reads:"
                + " p50 \(micros(samples[iterations / 2]))us"
                + " p99 \(micros(samples[iterations * 99 / 100]))us"
                + " max \(micros(samples[iterations - 1]))us"
        )
        #expect(samples.count == iterations)
    }

    private func measureFlood(readSize: Int) async {
        let total = 64 * 1024 * 1024
        let chunk = [UInt8](repeating: 0x61, count: readSize)
        let target = NullTarget()
        let pump = await target.pump()
        let drain = Task { await pump.run() }

        let started = ContinuousClock.now
        for _ in 0..<(total / readSize) {
            await pump.ingest(chunk[...])
        }
        await waitUntil { await pump.pendingByteCount == 0 }
        let elapsed = ContinuousClock.now - started
        drain.cancel()
        await drain.value

        let metrics = await pump.metrics
        let seconds = seconds(elapsed)
        let megabytes = Double(total) / (1024 * 1024)
        print(
            "pump throughput at \(readSize / 1024)KB reads:"
                + " \(String(format: "%.0f", megabytes / seconds))MB/s"
                + " in \(String(format: "%.3f", seconds))s,"
                + " \(metrics.deliveredSlices) hops,"
                + " \(metrics.deliveredBytes / max(metrics.deliveredSlices, 1)) bytes per hop,"
                + " \(metrics.suspensions) suspensions"
        )
        #expect(metrics.deliveredBytes == total)
    }

    private func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }

    private func micros(_ duration: Duration) -> String {
        String(format: "%.1f", seconds(duration) * 1_000_000)
    }
}

@MainActor
final class NullTarget {
    private(set) var receivedBytes = 0

    func pump() -> OutputPump {
        OutputPump { [self] bytes in receivedBytes += bytes.count }
    }
}

@MainActor
final class TimestampingTarget {
    private(set) var receivedAt: [ContinuousClock.Instant] = []

    func pump() -> OutputPump {
        OutputPump { [self] _ in receivedAt.append(ContinuousClock.now) }
    }
}
