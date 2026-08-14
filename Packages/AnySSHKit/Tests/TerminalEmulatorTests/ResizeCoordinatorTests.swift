import AnySSHCore
import Testing

@testable import TerminalEmulator

@Suite struct ResizeCoordinatorTests {
    private func coordinator(
        _ clock: VirtualClock,
        _ gate: WaitGate,
        _ recorder: ResizeRecorder,
        started: TerminalSize? = TerminalSize(columns: 80, rows: 24)
    ) -> ResizeCoordinator {
        ResizeCoordinator(
            window: .milliseconds(80),
            started: started,
            now: { clock.now },
            wait: { await gate.wait($0) },
            apply: { await recorder.record($0) }
        )
    }

    @Test func thirtyEventsInsideTheWindowProduceOneResize() async {
        let clock = VirtualClock()
        let gate = WaitGate()
        let recorder = ResizeRecorder()
        let coordinator = coordinator(clock, gate, recorder)

        for step in 0..<30 {
            await coordinator.record(TerminalSize(columns: 81 + step, rows: 24), at: clock.now)
            clock.advance(by: .milliseconds(2))
        }
        await gate.settle()
        #expect(await recorder.sizes.isEmpty)

        clock.advance(by: .milliseconds(80))
        await gate.release()
        await waitUntil { await coordinator.deliveredCount == 1 }

        #expect(await recorder.sizes == [TerminalSize(columns: 110, rows: 24)])
        #expect(await coordinator.waitCount == 1)
    }

    @Test func anEventAfterTheWindowProducesASecondResize() async {
        let clock = VirtualClock()
        let gate = WaitGate()
        let recorder = ResizeRecorder()
        let coordinator = coordinator(clock, gate, recorder)

        await coordinator.record(TerminalSize(columns: 100, rows: 40), at: clock.now)
        await gate.settle()
        clock.advance(by: .milliseconds(80))
        await gate.release()
        await waitUntil { await coordinator.deliveredCount == 1 }

        clock.advance(by: .milliseconds(120))
        await coordinator.record(TerminalSize(columns: 132, rows: 43), at: clock.now)
        await gate.settle()
        clock.advance(by: .milliseconds(80))
        await gate.release()
        await waitUntil { await coordinator.deliveredCount == 2 }

        #expect(
            await recorder.sizes == [
                TerminalSize(columns: 100, rows: 40),
                TerminalSize(columns: 132, rows: 43),
            ]
        )
        #expect(await coordinator.waitCount == 2)
    }

    @Test func anUnchangedGridProducesNoResizeAndNoWait() async {
        let clock = VirtualClock()
        let gate = WaitGate()
        let recorder = ResizeRecorder()
        let coordinator = coordinator(clock, gate, recorder)

        for _ in 0..<10 {
            await coordinator.record(TerminalSize(columns: 80, rows: 24), at: clock.now)
            clock.advance(by: .milliseconds(2))
        }

        #expect(await coordinator.deliveredCount == 0)
        #expect(await gate.waits == 0)
        #expect(await recorder.sizes.isEmpty)
    }

    @Test func aReorderedEventDoesNotOverwriteALaterSize() async {
        let clock = VirtualClock()
        let gate = WaitGate()
        let recorder = ResizeRecorder()
        let coordinator = coordinator(clock, gate, recorder)
        let first = clock.now

        await coordinator.record(TerminalSize(columns: 132, rows: 43), at: first + .milliseconds(10))
        await coordinator.record(TerminalSize(columns: 100, rows: 40), at: first)
        await gate.settle()
        clock.advance(by: .milliseconds(200))
        await gate.release()
        await waitUntil { await coordinator.deliveredCount == 1 }

        #expect(await recorder.sizes == [TerminalSize(columns: 132, rows: 43)])
    }

    @Test func flushDeliversThePendingSizeImmediately() async {
        let clock = VirtualClock()
        let gate = WaitGate()
        let recorder = ResizeRecorder()
        let coordinator = coordinator(clock, gate, recorder)

        await coordinator.record(TerminalSize(columns: 120, rows: 30), at: clock.now)
        await coordinator.flush()

        #expect(await recorder.sizes == [TerminalSize(columns: 120, rows: 30)])
        #expect(await coordinator.deliveredCount == 1)
    }

    @Test func anEngineSizeReachesTheTransport() async {
        let transport = RecordingTransport()
        let coordinator = ResizeCoordinator.driving(transport, window: .milliseconds(1))

        coordinator.sizeChanged(to: TerminalSize(columns: 100, rows: 40))

        #expect(await settled(transport))
        #expect(await transport.sizes == [TerminalSize(columns: 100, rows: 40)])
    }

    private func settled(_ transport: RecordingTransport, ceiling: Duration = .seconds(60)) async -> Bool {
        let limit = ContinuousClock.now + ceiling
        while await transport.sizes.isEmpty {
            guard ContinuousClock.now < limit else { return false }
            await Task.yield()
        }
        return true
    }

    @Test func theEntryPointFromTheEngineNeedsNoAwait() async {
        let clock = VirtualClock()
        let gate = WaitGate()
        let recorder = ResizeRecorder()
        let coordinator = coordinator(clock, gate, recorder, started: nil)

        coordinator.sizeChanged(to: TerminalSize(columns: 90, rows: 30))
        await gate.settle()
        clock.advance(by: .milliseconds(80))
        await gate.release()
        await waitUntil { await coordinator.deliveredCount == 1 }

        #expect(await recorder.sizes == [TerminalSize(columns: 90, rows: 30)])
    }
}
