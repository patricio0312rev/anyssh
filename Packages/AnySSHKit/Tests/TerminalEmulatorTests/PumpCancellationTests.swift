import Testing

@testable import TerminalEmulator

@Suite struct PumpCancellationTests {
    static let total = 512 * 1024
    static let configuration = PumpConfiguration(
        sliceLimit: 4 * 1024,
        highWaterMark: 1024 * 1024
    )

    @Test func cancellingMidDeliveryLosesNothingAndRepeatsNothing() async {
        var generator = SplitMix64(seed: 0x0C0F_FEE0)
        let source = generator.bytes(Self.total)
        let target = RecordingTarget()
        await target.stall(fromSlice: 3)
        let pump = await target.pump(configuration: Self.configuration)

        var offset = 0
        for length in generator.chunkLengths(total: Self.total, upTo: 8 * 1024) {
            await pump.ingest(source[offset..<(offset + length)])
            offset += length
        }

        let interrupted = Task { await pump.run() }
        await waitUntil { await target.sliceLengths.count == 3 }
        interrupted.cancel()
        await target.release()
        await interrupted.value

        let afterCancellation = await pump.metrics
        #expect(afterCancellation.deliveredSlices == 3)
        #expect(afterCancellation.deliveredBytes < Self.total)

        let resumed = Task { await pump.run() }
        await waitUntil { await pump.pendingByteCount == 0 }
        resumed.cancel()
        await resumed.value

        #expect(await target.finalizedDigest() == StreamDigest.of(source))
        #expect(await pump.metrics.deliveredBytes == Self.total)
        #expect(await target.receivedBytes == Self.total)
    }

    @Test func cancellingAnIdleDrainReturns() async {
        let target = RecordingTarget()
        let pump = await target.pump(configuration: Self.configuration)

        let drain = Task { await pump.run() }
        await pump.ingest([UInt8](repeating: 0x7E, count: 32)[...])
        await waitUntil { await pump.pendingByteCount == 0 }
        drain.cancel()
        await drain.value

        #expect(await target.receivedBytes == 32)
    }

    @Test func aSecondConcurrentDrainDoesNotInterleaveSlices() async {
        var generator = SplitMix64(seed: 0x0BAD_F00D)
        let source = generator.bytes(Self.total)
        let target = RecordingTarget()
        let pump = await target.pump(configuration: Self.configuration)

        let first = Task { await pump.run() }
        let second = Task { await pump.run() }
        var offset = 0
        for length in generator.chunkLengths(total: Self.total, upTo: 8 * 1024) {
            await pump.ingest(source[offset..<(offset + length)])
            offset += length
        }
        await waitUntil { await pump.pendingByteCount == 0 }
        first.cancel()
        second.cancel()
        await first.value
        await second.value

        #expect(await target.finalizedDigest() == StreamDigest.of(source))
    }
}
