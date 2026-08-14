import Testing

@testable import AnySSHUI

@Suite struct PaletteModelTests {
    private let entries = [
        PaletteEntry(
            id: "app.newConnection",
            title: "New Connection",
            keyLabel: "Cmd+N",
            isEnabled: true,
            disabledReason: nil
        ),
        PaletteEntry(
            id: "session.next",
            title: "Next Session",
            keyLabel: nil,
            isEnabled: false,
            disabledReason: "One session open"
        ),
        PaletteEntry(
            id: "session.previous",
            title: "Previous Session",
            keyLabel: nil,
            isEnabled: true,
            disabledReason: nil
        ),
    ]

    @Test func selectionLandsOnTheFirstEnabledMatch() {
        let model = CommandPaletteModel(entries: entries)
        #expect(model.selected?.id == "app.newConnection")
    }

    @Test func filteringMatchesTitleAndIdentifier() {
        var model = CommandPaletteModel(entries: entries)
        model.setQuery("  SESSION ")
        #expect(model.matches.map(\.id) == ["session.next", "session.previous"])
        #expect(model.selected?.id == "session.previous")
    }

    @Test func movementSkipsDisabledRows() {
        var model = CommandPaletteModel(entries: entries)
        model.moveDown()
        #expect(model.selected?.id == "session.previous")
        model.moveDown()
        #expect(model.selected?.id == "app.newConnection")
        model.moveUp()
        #expect(model.selected?.id == "session.previous")
    }

    @Test func anEntirelyDisabledListKeepsSelectionInert() {
        var model = CommandPaletteModel(
            entries: [
                PaletteEntry(
                    id: "app.later",
                    title: "Later",
                    keyLabel: nil,
                    isEnabled: false,
                    disabledReason: "Available in a later build"
                )
            ]
        )
        #expect(model.selected?.isEnabled == false)
        model.moveDown()
        #expect(model.selection == 0)
    }

    @Test func anEmptyMatchSetHasNoSelection() {
        var model = CommandPaletteModel(entries: entries)
        model.setQuery("zzz")
        #expect(model.matches.isEmpty)
        #expect(model.selected == nil)
    }
}
