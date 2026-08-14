public enum ShortcutPanelDefaults {
    public static let tmuxPrefix = "C-b"
    public static let herdrPrefix = "C-b"
    public static let tmux = ShortcutPanel(
        id: "tmux",
        scope: .tmux,
        name: "tmux",
        entries: tmuxEntries(prefix: tmuxPrefix)
    )

    public static let herdr = ShortcutPanel(
        id: "herdr",
        scope: .herdr,
        name: "herdr",
        entries: herdrEntries(prefix: herdrPrefix)
    )

    public static let agent = ShortcutPanel(
        id: "agent",
        scope: .agent,
        name: "Agent",
        entries: [
            ShortcutPanel.Entry(id: "clear", label: "/clear", payload: .text("/clear")),
            ShortcutPanel.Entry(id: "compact", label: "/compact", payload: .text("/compact")),
            ShortcutPanel.Entry(id: "escape", label: "Esc", payload: .chord("Esc")),
            ShortcutPanel.Entry(id: "interrupt", label: "Ctrl-C", payload: .chord("C-c")),
        ]
    )

    public static let standard = ShortcutPanelLayout(panels: [tmux, herdr, agent])

    static func tmuxEntries(prefix: String) -> [ShortcutPanel.Entry] {
        standardEntries(
            prefix: prefix,
            actions: [
                ("next-window", "Next window", "n"),
                ("previous-window", "Previous window", "p"),
                ("new-window", "New window", "c"),
                ("split-horizontal", "Split horizontal", "%"),
                ("split-vertical", "Split vertical", "\""),
                ("detach", "Detach", "d"),
                ("kill-pane", "Kill pane", "x"),
                ("rename", "Rename window", "Comma"),
            ]
        )
    }

    public static let herdrDetachKey = "q"

    static func herdrEntries(prefix: String) -> [ShortcutPanel.Entry] {
        standardEntries(
            prefix: prefix,
            actions: [
                ("previous-tab", "Previous tab", "p"),
                ("next-tab", "Next tab", "n"),
                ("new-tab", "New tab", "t"),
                ("zoom", "Zoom", "z"),
                ("workspace-picker", "Workspace picker", "w"),
                ("detach", "Detach", herdrDetachKey),
            ]
        )
    }

    private static func standardEntries(
        prefix: String,
        actions: [(id: String, label: String, key: String)]
    ) -> [ShortcutPanel.Entry] {
        actions.map { action in
            ShortcutPanel.Entry(
                id: action.id,
                label: action.label,
                payload: .chord("\(prefix), \(action.key)")
            )
        }
    }
}
