import Testing

@testable import TerminalEmulator

@Suite struct PumpCoalescingTests {
    static let reads = 700
    static let readSize = CountingEngine.bytesPerPrompt

    private func flood(_ harness: Harness, reads: Int = reads, size: Int = readSize) async -> OutputPump {
        let pump = harness.pump
        let chunk = [UInt8](repeating: 0x2E, count: size)
        let drain = Task { await pump.run() }
        for _ in 0..<reads {
            await pump.ingest(chunk[...])
        }
        await waitUntil { await pump.pendingByteCount == 0 }
        drain.cancel()
        await drain.value
        return pump
    }

    @Test func sevenHundredSmallReadsCostAtMostTwentyFourMainActorHops() async {
        let harness = await Harness()
        let metrics = await flood(harness).metrics

        #expect(metrics.deliveredSlices <= 24)
        #expect(metrics.deliveredBytes == Self.reads * Self.readSize)
        #expect(await harness.engine.fedBytes == Self.reads * Self.readSize)
        #expect(await harness.engine.feedCount == metrics.deliveredSlices)
    }

    @Test func aTitlePerPromptBecomesAtMostOneChromeUpdatePerDrain() async {
        let harness = await Harness()
        let metrics = await flood(harness).metrics
        let deliveries = await harness.recorder.deliveries

        #expect(await harness.engine.titlesEmitted == Self.reads)
        #expect(deliveries.count <= metrics.deliveredSlices)
        #expect(deliveries.count <= 24)
        #expect(deliveries.last?.title == "prompt-\(Self.reads)")
    }

    @Test func aDrainWithNoMetadataDeliversNothingToTheChrome() async {
        let harness = await Harness()
        let metrics = await flood(harness, reads: 1, size: 10).metrics

        #expect(metrics.deliveredSlices == 1)
        #expect(await harness.recorder.deliveries.isEmpty)
    }
}

@MainActor
private struct Harness {
    let engine: CountingEngine
    let recorder: MetadataRecorder
    let pump: OutputPump

    init() {
        let coalescer = TerminalMetadataCoalescer()
        let recorder = MetadataRecorder()
        engine = CountingEngine(metadata: coalescer)
        self.recorder = recorder
        pump = EngineDrainTarget(engine: engine, metadata: coalescer) { recorder.record($0) }
            .pump()
    }
}
