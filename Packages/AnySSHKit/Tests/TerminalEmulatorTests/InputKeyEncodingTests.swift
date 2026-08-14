import Testing

@testable import TerminalEmulator

@Suite struct KeyEncodingTests {
    @Test(arguments: InputEncodingTable.all)
    func encodesTheExactSequence(_ row: KeyEncodingCase) {
        let encoded = KeyEncoder(mode: row.mode).encode(row.key, modifiers: row.modifiers)

        #expect(encoded == row.expected, "\(row.name) encoded as \(encoded)")
    }

    @Test func theTableCoversAtLeastSixtyRows() {
        #expect(InputEncodingTable.all.count >= 60)
    }

    @Test func everyRowIsNamedOnce() {
        let names = Set(InputEncodingTable.all.map(\.name))

        #expect(names.count == InputEncodingTable.all.count)
    }

    @Test(arguments: [TerminalKey.up, .down, .left, .right, .home, .end])
    func applicationCursorModeChangesOnlyTheUnmodifiedForm(_ key: TerminalKey) {
        let normal = KeyEncoder(mode: InputModes.normal)
        let application = KeyEncoder(mode: InputModes.application)

        #expect(normal.encode(key) != application.encode(key))
        #expect(normal.encode(key, modifiers: .control) == application.encode(key, modifiers: .control))
    }

    @Test(arguments: InputEncodingTable.all)
    func latchedModifiersMatchReportedModifiers(_ row: KeyEncodingCase) {
        var input = TerminalInput(mode: row.mode)
        for modifier in LatchedModifier.allCases where row.modifiers.contains(modifier.keyModifier) {
            input.tap(modifier)
        }

        #expect(input.send(row.key) == row.expected)
        #expect(input.latch.isEmpty)
    }
}
