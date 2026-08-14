import AnySSHCore
import Testing

@testable import TerminalEmulator

@Suite struct BindingSyntaxTests {
    struct ValidCase: Sendable {
        let name: String
        let modifier: KeyModifiers
        let text: String
        let bytes: [UInt8]
    }

    static let validCases: [ValidCase] = [
        ValidCase(name: "ctrl b", modifier: .control, text: "b", bytes: [0x02]),
        ValidCase(name: "ctrl b1", modifier: .control, text: "b1", bytes: [0x02, 0x31]),
        ValidCase(name: "ctrl a,b", modifier: .control, text: "a,b", bytes: [0x01, 0x02]),
        ValidCase(name: "ctrl god", modifier: .control, text: "god", bytes: [0x07, 0x6f, 0x64]),
        ValidCase(name: "ctrl a,,b", modifier: .control, text: "a,,b", bytes: [0x01, 0x2c, 0x02]),
        ValidCase(name: "verbatim a,b", modifier: [], text: "a,b", bytes: [0x61, 0x2c, 0x62]),
        ValidCase(
            name: "ctrl text:/clear", modifier: .control, text: "text:/clear",
            bytes: [0x2f, 0x63, 0x6c, 0x65, 0x61, 0x72]),
        ValidCase(name: "ctrl ,,", modifier: .control, text: ",,", bytes: [0x2c]),
        ValidCase(name: "alt x", modifier: .alt, text: "x", bytes: [0x1b, 0x78]),
        ValidCase(name: "alt ls", modifier: .alt, text: "ls", bytes: [0x1b, 0x6c, 0x73]),
        ValidCase(name: "shift ab", modifier: .shift, text: "ab", bytes: [0x41, 0x62]),
        ValidCase(name: "ctrl a b", modifier: .control, text: "a b", bytes: [0x01, 0x20, 0x62]),
        ValidCase(name: "ctrl 2", modifier: .control, text: "2", bytes: [0x00]),
        ValidCase(
            name: "verbatim hello", modifier: [], text: "hello", bytes: [0x68, 0x65, 0x6c, 0x6c, 0x6f]),
        ValidCase(name: "verbatim unicode", modifier: [], text: "olé", bytes: [0x6f, 0x6c, 0xc3, 0xa9]),
        ValidCase(
            name: "verbatim a,,b keeps both commas", modifier: [], text: "a,,b",
            bytes: [0x61, 0x2c, 0x2c, 0x62]),
        ValidCase(
            name: "ctrl text:a,b stays verbatim", modifier: .control, text: "text:a,b",
            bytes: [0x61, 0x2c, 0x62]),
        ValidCase(
            name: "ctrl text keeps interior space", modifier: .control, text: "text:hello world",
            bytes: [0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64]),
    ]

    struct MalformedCase: Sendable {
        let name: String
        let modifier: KeyModifiers
        let text: String
        let error: SimpleBindingSyntaxError
    }

    static let malformedCases: [MalformedCase] = [
        MalformedCase(name: "empty", modifier: [], text: "", error: .emptyText),
        MalformedCase(name: "empty with modifier", modifier: .control, text: "", error: .emptyText),
        MalformedCase(name: "whitespace only", modifier: [], text: "   ", error: .emptyText),
        MalformedCase(name: "text: with nothing", modifier: [], text: "text:", error: .emptyText),
        MalformedCase(
            name: "text: with nothing and modifier", modifier: .control, text: "text:", error: .emptyText),
        MalformedCase(name: "leading comma", modifier: .control, text: ",a", error: .leadingComma),
        MalformedCase(name: "trailing comma", modifier: .control, text: "a,", error: .trailingComma),
        MalformedCase(name: "line break", modifier: [], text: "a\nb", error: .newlineInText),
    ]

    @Test(arguments: validCases)
    func exactByteOutput(row: ValidCase) throws {
        let binding = try SimpleBindingParser.parse(modifier: row.modifier, text: row.text)
        #expect(binding.bytes(using: KeyEncoder()) == row.bytes, "\(row.name)")
    }

    @Test(arguments: malformedCases)
    func namedRejection(row: MalformedCase) {
        #expect(throws: row.error) {
            try SimpleBindingParser.parse(modifier: row.modifier, text: row.text)
        }
    }

    @Test func ctrlGodEmitsExactlyBellOhDee() throws {
        let binding = try SimpleBindingParser.parse(modifier: .control, text: "god")
        #expect(binding.bytes(using: KeyEncoder()) == [0x07, 0x6f, 0x64])
    }

    @Test func editorPreviewReusesPhase23Renderer() {
        #expect(BindingComposer.preview(modifier: [], text: "C-b, S-t") == "^B T")
        #expect(BindingComposer.preview(modifier: .control, text: "b1") == "^B 1")
        #expect(BindingComposer.preview(modifier: [], text: "/clear") == "/clear")
    }

    @Test func chordComposedBySimpleBuilderRoundTripsThroughSyntaxText() throws {
        let binding = try SimpleBindingParser.parse(modifier: .control, text: "a,,b")
        guard case .chord(let chord) = binding else {
            Issue.record("expected a chord")
            return
        }
        #expect(chord.syntaxText == "C-a, Comma, C-b")
        let reparsed = try Chord(parsing: chord.syntaxText)
        #expect(KeyEncoder().encode(reparsed) == [0x01, 0x2c, 0x02])
    }

    @Test func panelPayloadEncodesToTheSameBytes() {
        #expect(ShortcutPanel.Entry.Payload.chord("C-a, n").bytes() == [0x01, 0x6e])
        #expect(ShortcutPanel.Entry.Payload.text("/clear").bytes() == [0x2f, 0x63, 0x6c, 0x65, 0x61, 0x72])
    }
}
