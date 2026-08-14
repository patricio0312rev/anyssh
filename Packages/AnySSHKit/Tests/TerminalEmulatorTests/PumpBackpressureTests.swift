import Testing

@testable import TerminalEmulator

@Suite struct PumpBackpressureTests {
    static let highWaterMark = 64 * 1024
    static let configuration = PumpConfiguration(
        sliceLimit: 16 * 1024,
        highWaterMark: highWaterMark
    )

    @Test func aRendererThatNeverReturnsParksTheProducerInsteadOfGrowingMemory() async {
        let chunk = [UInt8](repeating: 0x41, count: 8 * 1024)
        let chunks = 64
        let target = RecordingTarget()
        await target.stall(fromSlice: 1)
        let pump = await target.pump(configuration: Self.configuration)

        let drain = Task { await pump.run() }
        let accepted = AcceptedCounter()
        let producer = Task {
            for _ in 0..<chunks {
                await pump.ingest(chunk[...])
                await accepted.record()
            }
        }
        await waitUntil { await pump.metrics.suspensions > 0 }

        #expect(await accepted.count < chunks)
        let peak = await pump.metrics.peakPendingBytes
        #expect(peak >= Self.highWaterMark)
        #expect(peak < Self.highWaterMark * 2)

        await target.release()
        await producer.value
        await waitUntil { await pump.pendingByteCount == 0 }
        drain.cancel()
        await drain.value

        #expect(await target.receivedBytes == chunks * chunk.count)
        #expect(await pump.metrics.peakPendingBytes < Self.highWaterMark * 2)
    }

    @Test func peakStaysBelowTwiceTheMarkWhenAFullReadLandsJustBelowIt() async {
        let target = RecordingTarget()
        let pump = await target.pump(configuration: Self.configuration)
        let filler = [UInt8](repeating: 0x2A, count: Self.highWaterMark - 1)
        let read = [UInt8](repeating: 0x2A, count: Self.highWaterMark)

        await pump.ingest(filler[...])
        await pump.ingest(read[...])

        let metrics = await pump.metrics
        #expect(await pump.pendingByteCount == Self.highWaterMark * 2 - 1)
        #expect(metrics.peakPendingBytes < Self.highWaterMark * 2)
        #expect(metrics.suspensions == 0)
        #expect(await target.sliceLengths.isEmpty)
    }
}
