import AnySSHCore
import Testing

@testable import TerminalEmulator

@Suite struct ResizeDebounceTests {
    private let start = ContinuousClock.now

    @Test func aBurstInsideTheWindowSendsOnlyItsLastSize() {
        var debounce = ResizeDebounce(delivered: TerminalSize(columns: 80, rows: 24))
        var scheduled = 0

        for step in 0..<30 {
            let size = TerminalSize(columns: 81 + step, rows: 24)
            if case .scheduled = debounce.record(size, at: start + .milliseconds(step * 2)) {
                scheduled += 1
            }
            #expect(debounce.fire(at: start + .milliseconds(step * 2)) == nil)
        }

        #expect(scheduled == 30)
        #expect(debounce.fire(at: start + .milliseconds(137)) == nil)
        #expect(debounce.fire(at: start + .milliseconds(138)) == TerminalSize(columns: 110, rows: 24))
        #expect(debounce.fire(at: start + .seconds(10)) == nil)
    }

    @Test func anEventAfterTheWindowSendsASecondSize() {
        var debounce = ResizeDebounce(delivered: TerminalSize(columns: 80, rows: 24))
        for step in 0..<30 {
            debounce.record(TerminalSize(columns: 81 + step, rows: 24), at: start + .milliseconds(step * 2))
        }
        #expect(debounce.fire(at: start + .milliseconds(138)) != nil)

        debounce.record(TerminalSize(columns: 132, rows: 43), at: start + .milliseconds(258))
        #expect(debounce.fire(at: start + .milliseconds(337)) == nil)
        #expect(debounce.fire(at: start + .milliseconds(338)) == TerminalSize(columns: 132, rows: 43))
    }

    @Test func anUnchangedGridSchedulesNothing() {
        let size = TerminalSize(columns: 100, rows: 40)
        var debounce = ResizeDebounce(delivered: size)

        #expect(debounce.record(size, at: start) == .unchanged)
        #expect(debounce.deadline == nil)
        #expect(debounce.fire(at: start + .seconds(1)) == nil)
    }

    @Test func aRotationWithTheSameCellCountIsStillSent() {
        var debounce = ResizeDebounce(delivered: TerminalSize(columns: 80, rows: 24))
        let rotated = TerminalSize(columns: 24, rows: 80)

        #expect(rotated.cellCount == TerminalSize(columns: 80, rows: 24).cellCount)
        #expect(debounce.record(rotated, at: start) != .unchanged)
        #expect(debounce.fire(at: start + .milliseconds(80)) == rotated)
    }

    @Test func aPixelOnlyChangeSchedulesNothing() {
        var debounce = ResizeDebounce(
            delivered: TerminalSize(columns: 80, rows: 24, pixelWidth: 800, pixelHeight: 480)
        )
        let jiggled = TerminalSize(columns: 80, rows: 24, pixelWidth: 801, pixelHeight: 480)

        #expect(debounce.record(jiggled, at: start) == .unchanged)
        #expect(debounce.deadline == nil)
    }

    @Test func theFirstSizeAfterAnUnknownStartIsAlwaysSent() {
        var debounce = ResizeDebounce()
        let size = TerminalSize(columns: 80, rows: 24)

        #expect(debounce.record(size, at: start) == .scheduled(due: start + .milliseconds(80)))
        #expect(debounce.pendingSize == size)
    }

    @Test func aBurstThatReturnsToTheDeliveredGridSendsNothing() {
        let delivered = TerminalSize(columns: 80, rows: 24)
        var debounce = ResizeDebounce(delivered: delivered)

        debounce.record(TerminalSize(columns: 100, rows: 40), at: start)
        #expect(debounce.record(delivered, at: start + .milliseconds(10)) != .unchanged)
        #expect(debounce.fire(at: start + .milliseconds(90)) == nil)
        #expect(debounce.deadline == nil)
    }
}
