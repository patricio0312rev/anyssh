import AnySSHMocks
import Foundation
import Testing

@testable import TerminalEmulator

@Suite struct ThroughputTests {
    @Test func terminalFloodDeepLinkSelectsTheMockScenario() {
        let url = TerminalFloodTrigger.url()
        #expect(TerminalFloodTrigger.link == "anyssh://terminal/flood")
        #expect(url.flatMap(TerminalFloodTrigger.scenario(from:)) == .terminalFlood)
        #expect(TerminalFloodTrigger.scenario(from: URL(string: "anyssh://error/app.failed")!) == nil)
    }

    @Test func yesFixtureMaintainsChecksumAndPerformanceThresholds() async {
        let tier = ThroughputTier.current
        let input = ThroughputFixtureInput.yes()
        let sample = Array(input.bytes.prefix(64 * 1024))
        let totalBytes = tier == .hostE1 ? 8 * 1024 * 1024 : 20 * 1024 * 1024 * 30
        let repetitions = totalBytes / sample.count
        let configuration = PumpConfiguration()
        let target = await MainActor.run { ThroughputDrainTarget() }
        let pump = await MainActor.run {
            OutputPump(configuration: configuration) { [target] bytes in target.receive(bytes) }
        }
        let drain = Task { await pump.run() }
        let producer = MockByteProducer(
            configuration: .init(bytesPerSecond: 20 * 1024 * 1024, chunkSize: 64 * 1024)
        )
        let started = ContinuousClock.now
        let report = await producer.replay(sample, repetitions: repetitions, to: pump)
        let elapsed = started.duration(to: .now)
        let didSettle = await settled(target, expectedBytes: report.bytesEmitted)
        #expect(didSettle)

        let bytes = await MainActor.run { target.bytes }
        let checksum = await MainActor.run { target.checksum() }
        let block = await MainActor.run { target.longestBlockMilliseconds }
        let dropped = await MainActor.run { target.droppedFramePercentage }
        let echoes = 100
        let echoed = await measureInputEcho(pump: pump, target: target, samples: echoes)
        drain.cancel()
        await drain.value
        let metrics = await pump.metrics
        let memory = residentMemoryBytes()
        let seconds = seconds(elapsed)
        let sustained = Double(report.bytesEmitted) / seconds / 1_000_000
        let latency = await MainActor.run { target.inputEchoP99Milliseconds() }
        let artifact = ThroughputArtifact.write(
            tier: tier,
            sustained: sustained,
            peakResidentBytes: memory,
            longestBlockMilliseconds: block,
            droppedFramePercentage: dropped,
            inputEchoP99Milliseconds: latency
        )

        print("throughput tier: \(tier.rawValue)")
        print("throughput fixture: \(input.source), \(sample.count) bytes")
        print("throughput sustained: \(String(format: "%.2f", sustained)) MB/s")
        print("throughput bytes: \(bytes), peak resident: \(memory) bytes")
        print("throughput longest main-thread block: \(String(format: "%.3f", block)) ms")
        print("throughput dropped frames: \(String(format: "%.3f", dropped))%")
        print("throughput input echo p99: \(String(format: "%.3f", latency)) ms")
        print("throughput artifact: \(artifact?.path ?? "write failed")")

        #expect(artifact != nil)
        #expect(report.bytesEmitted == bytes)
        #expect(report.sha256 == checksum)
        #expect(echoed == echoes)
        #expect(metrics.deliveredBytes == report.bytesEmitted + echoes)
        #expect(metrics.deliveredSlices >= repetitions)
        #expect(metrics.peakPendingBytes <= configuration.highWaterMark)
    }

    @Test func allSliceSizesPreserveTheFixtureChecksum() async {
        let fixture = Array(ThroughputFixtureInput.yes().bytes.prefix(256 * 1024))
        for sliceSize in [16, 32, 64, 128].map({ $0 * 1024 }) {
            let target = await MainActor.run { ThroughputDrainTarget() }
            let pump = await MainActor.run {
                OutputPump(configuration: PumpConfiguration(sliceLimit: sliceSize)) { [target] bytes in
                    target.receive(bytes)
                }
            }
            let drain = Task { await pump.run() }
            let producer = MockByteProducer(
                configuration: .init(bytesPerSecond: Int.max, chunkSize: 16 * 1024),
                wait: { _ in await Task.yield() }
            )
            let report = await producer.replay(fixture, to: pump)
            let didSettle = await settled(target, expectedBytes: report.bytesEmitted)
            #expect(didSettle)
            drain.cancel()
            await drain.value
            let checksum = await MainActor.run { target.checksum() }
            #expect(report.sha256 == checksum)
            print("throughput slice \(sliceSize / 1024) KB: \(await pump.metrics.deliveredSlices) slices")
        }
    }

    private func measureInputEcho(
        pump: OutputPump,
        target: ThroughputDrainTarget,
        samples: Int
    ) async -> Int {
        for index in 0..<samples {
            await MainActor.run { target.armInput(at: .now) }
            await pump.ingest([0x78][...])
            for _ in 0..<10_000 {
                if await MainActor.run(body: { target.inputEchoCount }) > index { break }
                await Task.yield()
            }
        }
        return await MainActor.run { target.inputEchoCount }
    }

    private func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }
}
