import Testing

@testable import TerminalEmulator

@Suite struct ChordTests {
    private let encoder = KeyEncoder()

    @Test func parsesTheTwoStepFormFromTheResearch() throws {
        let chord = try Chord(parsing: "C-b, S-t")

        #expect(chord.steps == [KeyStroke(.character("b"), .control), KeyStroke(.character("t"), .shift)])
        #expect(chord.label == "^B T")
        #expect(encoder.encode(chord) == [0x02, 0x54])
    }

    @Test func parsesTheEmacsFormSeparatedByWhitespace() throws {
        let chord = try Chord(parsing: "C-x C-s")

        #expect(chord.label == "^X ^S")
        #expect(encoder.encode(chord) == [0x18, 0x13])
    }

    @Test(arguments: ["C-b,S-t", "C-b ,  S-t", "  C-b,\tS-t "])
    func separatorsAreCommaAndWhitespaceInAnyAmount(_ text: String) throws {
        #expect(try Chord(parsing: text).label == "^B T")
    }

    @Test(arguments: ["Ctrl-b", "control-B", "c-b"])
    func modifiersAcceptTheirLongSpellingsAndEitherCase(_ text: String) throws {
        #expect(try encoder.encode(Chord(parsing: text)) == [0x02])
    }

    @Test(arguments: ["M-f", "Alt-f", "meta-f", "opt-f"])
    func altHasFourSpellings(_ text: String) throws {
        #expect(try encoder.encode(Chord(parsing: text)) == [0x1b, 0x66])
    }

    @Test func namedKeysCarryTheirOwnSequences() throws {
        #expect(try encoder.encode(Chord(parsing: "C-Up")) == inputEscape("[1;5A"))
        #expect(try encoder.encode(Chord(parsing: "S-Tab")) == inputEscape("[Z"))
        #expect(try encoder.encode(Chord(parsing: "C-Space")) == [0x00])
        #expect(try encoder.encode(Chord(parsing: "F5")) == inputEscape("[15~"))
    }

    @Test func punctuationTheSyntaxSpendsIsReachableByName() throws {
        #expect(try encoder.encode(Chord(parsing: "C-b, Comma")) == [0x02, 0x2c])
        #expect(try encoder.encode(Chord(parsing: "Minus")) == [0x2d])
        #expect(try encoder.encode(Chord(parsing: "-")) == [0x2d])
    }

    @Test func labelsUseReadlineNotation() throws {
        #expect(try Chord(parsing: "C-Up").label == "^Up")
        #expect(try Chord(parsing: "S-Tab").label == "S-Tab")
        #expect(try Chord(parsing: "M-f").label == "M-f")
        #expect(try Chord(parsing: "M-C-x").label == "M-^X")
    }

    @Test(arguments: ["", "   ", ",,"])
    func emptyInputIsRefused(_ text: String) {
        #expect(throws: ChordSyntaxError.emptyChord) { try Chord(parsing: text) }
    }

    @Test func aModifierWithNoKeyIsRefused() {
        #expect(throws: ChordSyntaxError.danglingModifier(token: "C-")) { try Chord(parsing: "C-") }
    }

    @Test func anUnknownModifierIsRefused() {
        #expect(throws: ChordSyntaxError.unknownModifier(token: "X-b", modifier: "X")) {
            try Chord(parsing: "X-b")
        }
    }

    @Test func anUnknownKeyIsRefused() {
        #expect(throws: ChordSyntaxError.unknownKey(token: "C-Frobnicate", key: "Frobnicate")) {
            try Chord(parsing: "C-Frobnicate")
        }
    }

    @Test func aRepeatedModifierIsRefused() {
        #expect(throws: ChordSyntaxError.duplicateModifier(token: "C-C-b", modifier: "C")) {
            try Chord(parsing: "C-C-b")
        }
    }

    @Test func aRefusalNamesTheOffendingStepNotTheWholeString() {
        #expect(throws: ChordSyntaxError.unknownKey(token: "C-Nope", key: "Nope")) {
            try Chord(parsing: "C-x, C-Nope, C-s")
        }
    }

    @Test(arguments: ["^B T", "^Up", "M-f", "S-Tab"])
    func aLabelParsesBackIntoTheChordItCameFrom(_ label: String) throws {
        #expect(try Chord(parsing: label).label == label)
    }
}
