import Testing

@testable import TerminalEmulator

@Suite struct PumpLosslessTests {
    static let highWaterMark = 256 * 1024

    @Test func sixtyFourMegabytesArriveIntactAndInOrder() async {
        let total = 64 * 1024 * 1024
        var generator = SplitMix64(seed: 0x0A55_EED0)
        let source = generator.bytes(total)
        let lengths = generator.chunkLengths(total: total, upTo: 32 * 1024)

        let target = RecordingTarget()
        let pump = await target.pump(configuration: PumpConfiguration(highWaterMark: Self.highWaterMark))
        let drain = Task { await pump.run() }

        var offset = 0
        for length in lengths {
            await pump.ingest(source[offset..<(offset + length)])
            offset += length
        }
        await waitUntil { await pump.pendingByteCount == 0 }
        drain.cancel()
        await drain.value

        let metrics = await pump.metrics
        #expect(await target.finalizedDigest() == StreamDigest.of(source))
        #expect(metrics.deliveredBytes == total)
        #expect(await target.receivedBytes == total)
        #expect(metrics.suspensions > 200)
        #expect(metrics.peakPendingBytes < Self.highWaterMark * 2)
        #expect(await target.sliceLengths.allSatisfy { $0 <= PumpConfiguration.default.sliceLimit })
    }
}
