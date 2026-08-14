import AnySSHUI

enum PaletteScenarioEntries {
    static let all = [
        PaletteEntry(
            id: "app.newConnection",
            title: "New Connection",
            keyLabel: "Cmd+N",
            isEnabled: true,
            disabledReason: nil
        ),
        PaletteEntry(
            id: "app.openSwitcher",
            title: "Open Switcher",
            keyLabel: "Cmd+O",
            isEnabled: true,
            disabledReason: nil
        ),
        PaletteEntry(
            id: "session.next",
            title: "Next Session",
            keyLabel: nil,
            isEnabled: true,
            disabledReason: nil
        ),
        PaletteEntry(
            id: "session.activateTwo",
            title: "Session 2",
            keyLabel: "Cmd+2",
            isEnabled: false,
            disabledReason: "One session open"
        ),
        PaletteEntry(
            id: "app.openJumpTo",
            title: "Open Jump to",
            keyLabel: nil,
            isEnabled: false,
            disabledReason: "No multiplexer on this host"
        ),
    ]
}
