import Foundation
import Testing

@testable import TerminalEmulator

@Suite struct TerminalModeResetTests {
    private var text: String { String(decoding: TerminalModeReset.bytes, as: UTF8.self) }

    @Test func everyInputModeAnOldProgramCouldLeaveOnIsTurnedOff() {
        for mode in [9, 1000, 1002, 1003, 1005, 1006, 1015, 1016, 1004, 2004, 2026] {
            #expect(text.contains("\u{1B}[?\(mode)l"))
        }
        #expect(text.contains("\u{1B}[=0;1u"))
    }

    @Test func theAlternateScreenIsLeftBeforeTheSoftReset() throws {
        let leave = try #require(text.range(of: "\u{1B}7\u{1B}[?1049l"))
        let soft = try #require(text.range(of: "\u{1B}[!p"))
        #expect(text.hasPrefix("\u{1B}7"))
        #expect(leave.upperBound <= soft.lowerBound)
        #expect(text.hasSuffix("\u{1B}[!p"))
    }

    @Test func theResetNeverClearsTheScreenOrTheScrollback() {
        #expect(!text.contains("\u{1B}c"))
        #expect(!text.contains("[2J"))
        #expect(!text.contains("[3J"))
    }

    @Test func theDividerSitsOnItsOwnDimLineAndEndsPlain() {
        let date = Date(timeIntervalSince1970: 0)
        let divider = String(decoding: ReconnectDivider.bytes(at: date), as: UTF8.self)
        #expect(divider.hasPrefix("\r\n\u{1B}[2m-- reconnected "))
        #expect(divider.hasSuffix(" --\u{1B}[0m\r\n"))
        #expect(divider.contains(ReconnectDivider.label(at: date)))
    }
}
