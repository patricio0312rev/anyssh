import AnySSHCore
import TerminalEmulator
import Testing

@testable import AnySSHUI

@Suite struct TerminalPumpDrainTests {
    @Test func aFloodArrivesIntactInFarFewerHopsThanReads() async throws {
        let engine = SwiftTermEngine(size: .standard, renderer: .coreText)
        let target = EngineDrainTarget(
            engine: engine,
            metadata: TerminalMetadataCoalescer(),
            deliverMetadata: { _ in }
        )
        let pump = target.pump()
        let reads = Self.reads(count: 256)
        let total = reads.reduce(0) { $0 + $1.count }

        let drain = Task { await pump.run() }
        await Task.detached {
            for read in reads {
                await pump.ingest(read[...])
            }
        }.value
        try await Self.settle(pump, until: total)
        drain.cancel()

        let metrics = await pump.metrics
        #expect(metrics.deliveredBytes == total)
        #expect(metrics.deliveredSlices < reads.count / 4)
        #expect(engine.describeScreen().contains("line 255 "))
    }

    private static func reads(count: Int) -> [[UInt8]] {
        (0..<count).map { index in
            Array("line \(index) \(String(repeating: "x", count: 200))\r\n".utf8)
        }
    }

    private static func settle(_ pump: OutputPump, until delivered: Int) async throws {
        for _ in 0..<1000 where await pump.metrics.deliveredBytes < delivered {
            try await Task.sleep(for: .milliseconds(1))
        }
    }
}
