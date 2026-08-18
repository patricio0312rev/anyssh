import Testing

@testable import TerminalEmulator

@Suite struct MouseWheelReportTests {
    @Test func aWheelUpNotchIsButtonSixtyFour() {
        let report = TerminalMouseReport(button: .wheelUp, column: 4, row: 9, pressed: true)

        #expect(String(decoding: report.sgrBytes, as: UTF8.self) == "\u{1B}[<64;5;10M")
    }

    @Test func aWheelDownNotchIsButtonSixtyFive() {
        let report = TerminalMouseReport(button: .wheelDown, column: 0, row: 0, pressed: true)

        #expect(String(decoding: report.sgrBytes, as: UTF8.self) == "\u{1B}[<65;1;1M")
    }

    @Test func aWheelNotchNeverReleases() {
        let report = TerminalMouseReport(button: .wheelUp, column: 0, row: 0, pressed: false)

        #expect(String(decoding: report.sgrBytes, as: UTF8.self).hasSuffix("M"))
        #expect(report.isWheel)
    }

    @Test func aButtonStillReportsBothEdges() {
        let down = TerminalMouseReport(button: .primary, column: 2, row: 3, pressed: true)
        let up = TerminalMouseReport(button: .primary, column: 2, row: 3, pressed: false)

        #expect(String(decoding: down.sgrBytes, as: UTF8.self) == "\u{1B}[<0;3;4M")
        #expect(String(decoding: up.sgrBytes, as: UTF8.self) == "\u{1B}[<0;3;4m")
        #expect(!down.isWheel)
    }

    @Test func aReleaseCarriesThePressedButtonNumber() {
        let release = TerminalMouseReport(button: .primary, column: 0, row: 0, pressed: false)

        #expect(String(decoding: release.sgrBytes, as: UTF8.self) == "\u{1B}[<0;1;1m")
    }
}
