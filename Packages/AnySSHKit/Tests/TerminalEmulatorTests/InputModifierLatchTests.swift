import Testing

@testable import TerminalEmulator

@Suite struct ModifierLatchTests {
    @Test func oneTapAppliesToTheNextKeyAndThenReleases() {
        var input = TerminalInput()
        input.tap(.control)

        #expect(input.latch.control == .oneShot)
        #expect(input.send(.character("c")) == [0x03])
        #expect(input.latch.control == .off)
        #expect(input.send(.character("c")) == [0x63])
    }

    @Test func twoTapsLockUntilAThirdTapClearsIt() {
        var input = TerminalInput()
        input.tap(.control)
        input.tap(.control)

        #expect(input.latch.control == .locked)
        #expect(input.send(.character("c")) == [0x03])
        #expect(input.send(.character("d")) == [0x04])
        #expect(input.send(.character("e")) == [0x05])
        #expect(input.latch.control == .locked)

        #expect(input.tap(.control) == .off)
        #expect(input.send(.character("c")) == [0x63])
    }

    @Test func twoOneShotsApplyTogetherAndClearTogether() {
        var input = TerminalInput()
        input.tap(.control)
        input.tap(.alt)

        #expect(input.latch.pending == [.control, .alt])
        #expect(input.send(.character("x")) == [0x1b, 0x18])
        #expect(input.latch.isEmpty)
    }

    @Test func aLockSurvivesTheKeyThatSpendsAOneShot() {
        var input = TerminalInput()
        input.tap(.control)
        input.tap(.control)
        input.tap(.alt)

        #expect(input.send(.character("x")) == [0x1b, 0x18])
        #expect(input.send(.character("x")) == [0x18])
        #expect(input.latch.alt == .off)
        #expect(input.latch.control == .locked)
    }

    @Test func aLatchAppliesToPrintableCharacters() {
        var input = TerminalInput()
        input.tap(.shift)

        #expect(input.send(.character("t")) == [0x54])
        #expect(input.send(.character("t")) == [0x74])
    }

    @Test func aLatchThatChangesNothingIsStillConsumed() {
        var input = TerminalInput()
        input.tap(.shift)

        #expect(input.send(.character("1")) == [0x31])
        #expect(input.latch.isEmpty)
    }

    @Test func tappingAnotherModifierDoesNotConsumeTheFirst() {
        var input = TerminalInput()
        input.tap(.control)
        input.tap(.alt)
        input.tap(.shift)

        #expect(input.latch.pending == [.control, .alt, .shift])
        #expect(input.send(.character("f")) == [0x1b, 0x06])
    }

    @Test func clearingDropsLocksAndOneShotsAlike() {
        var input = TerminalInput()
        input.tap(.control)
        input.tap(.control)
        input.tap(.alt)
        input.clearLatch()

        #expect(input.latch.isEmpty)
        #expect(input.send(.character("c")) == [0x63])
    }

    @Test(arguments: LatchedModifier.allCases)
    func everyModifierCyclesThroughTheSameThreeStates(_ modifier: LatchedModifier) {
        var latch = ModifierLatch()

        #expect(latch[modifier] == .off)
        #expect(latch.tap(modifier) == .oneShot)
        #expect(latch.tap(modifier) == .locked)
        #expect(latch.tap(modifier) == .off)
    }

    @Test func thePreviewShowsWhatIsPending() {
        var input = TerminalInput()
        #expect(input.preview.isEmpty)

        input.tap(.control)
        #expect(input.preview == "^")

        input.tap(.alt)
        #expect(input.preview == "M-^")
    }

    @Test func aLatchJoinsOnlyTheFirstStepOfAChord() throws {
        var input = TerminalInput()
        input.tap(.alt)
        let chord = try Chord(parsing: "C-x C-s")

        #expect(input.send(chord) == [0x1b, 0x18, 0x13])
        #expect(input.latch.isEmpty)
    }

    @Test func aPasteDoesNotConsumeTheLatch() {
        var input = TerminalInput()
        input.tap(.control)

        #expect(input.send(PastePayload("ls")) == [0x6c, 0x73])
        #expect(input.send(.character("c")) == [0x03])
    }
}
