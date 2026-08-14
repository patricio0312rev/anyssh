import Testing

@testable import TerminalEmulator

@Suite struct PasteEncodingTests {
    private static let start = inputEscape("[200~")
    private static let end = inputEscape("[201~")

    @Test func aPasteIsWrappedWhenTheRemoteAskedForBrackets() {
        let bytes = PastePayload("ls").bytes(mode: InputModes.bracketing)

        #expect(bytes == Self.start + [0x6c, 0x73] + Self.end)
    }

    @Test func aPasteIsBareWhenTheRemoteDidNot() {
        #expect(PastePayload("ls").bytes(mode: InputModes.normal) == [0x6c, 0x73])
    }

    @Test func anEmbeddedEndMarkerIsDropped() {
        let payload = PastePayload("echo safe\u{1b}[201~\nrm -rf /")
        let bytes = payload.bytes(mode: InputModes.bracketing)

        #expect(bytes == Self.start + Array("echo safe".utf8) + [0x0d] + Array("rm -rf /".utf8) + Self.end)
        #expect(bytes.count { $0 == 0x1b } == 2)
    }

    @Test(arguments: ["a\nb", "a\r\nb", "a\rb"])
    func everyLineBreakBecomesTheByteReturnSends(_ text: String) {
        #expect(PastePayload(text).bytes(mode: InputModes.normal) == [0x61, 0x0d, 0x62])
    }

    @Test func lineCountsAreWhatAPersonWouldCount() {
        #expect(PastePayload("").lineCount == 0)
        #expect(PastePayload("one").lineCount == 1)
        #expect(PastePayload("one\n").lineCount == 1)
        #expect(PastePayload("one\ntwo").lineCount == 2)
        #expect(PastePayload("one\r\ntwo\r\n").lineCount == 2)
    }

    @Test func fortyLinesCountAsForty() {
        let text = (1...40).map { "line \($0)" }.joined(separator: "\n")

        #expect(PastePayload(text).lineCount == 40)
        #expect(PastePayload(text + "\n").lineCount == 40)
        #expect(PastePayload(text).isMultiline)
    }

    @Test func aTrailingBreakIsReportedSeparatelyFromTheLineCount() {
        #expect(PastePayload("rm -rf /\n").endsWithLineBreak)
        #expect(!PastePayload("rm -rf /\n").isMultiline)
        #expect(!PastePayload("rm -rf /").endsWithLineBreak)
    }

    @Test func multibyteTextSurvivesTheRoundTrip() {
        let bytes = PastePayload("café\n").bytes(mode: InputModes.bracketing)

        #expect(bytes == Self.start + Array("café".utf8) + [0x0d] + Self.end)
    }
}
