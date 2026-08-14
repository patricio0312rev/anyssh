public enum ShortcutPanelBuilder {
    private static let herdrActionOrder = [
        "previous_tab", "next_tab", "new_tab", "zoom", "workspace_picker", "new_workspace",
        "detach",
    ]

    public static func make(
        kind: MultiplexerKind,
        capabilities: HostCapabilities?,
        bindings: MuxKeyBindings?,
        persisted: ShortcutPanelLayout?
    ) -> ShortcutPanelLayout {
        var panels = persisted?.panels ?? ShortcutPanelDefaults.standard.panels
        let tmuxActive = kind == .tmux || capabilities?.tmux.isAvailable == true
        let herdrActive = kind == .herdr || capabilities?.herdr.tool.isAvailable == true

        panels = panels.filter { panel in
            switch panel.scope {
            case .tmux: tmuxActive
            case .herdr: herdrActive
            case .agent, .custom: true
            }
        }

        var layout = ShortcutPanelLayout(panels: panels)
        if tmuxActive {
            layout = layout.replacing(tmuxPanel(bindings: bindings))
        }
        if herdrActive {
            layout = layout.replacing(herdrPanel(bindings: bindings))
        }
        if !layout.contains(scope: .agent) {
            layout = layout.replacing(ShortcutPanelDefaults.agent)
        }
        return layout
    }

    static func tmuxPanel(bindings: MuxKeyBindings?) -> ShortcutPanel {
        let prefix = Self.prefix(from: bindings, fallback: ShortcutPanelDefaults.tmuxPrefix)
        return ShortcutPanel(
            id: "tmux",
            scope: .tmux,
            name: "tmux",
            entries: ShortcutPanelDefaults.tmuxEntries(prefix: prefix)
        )
    }

    static func herdrPanel(bindings: MuxKeyBindings?) -> ShortcutPanel {
        guard let bindings, !bindings.chords.isEmpty else {
            let prefix = Self.prefix(from: bindings, fallback: ShortcutPanelDefaults.herdrPrefix)
            return ShortcutPanel(
                id: "herdr",
                scope: .herdr,
                name: "herdr",
                entries: ShortcutPanelDefaults.herdrEntries(prefix: prefix)
            )
        }
        let prefix = Self.prefix(from: bindings, fallback: ShortcutPanelDefaults.herdrPrefix)
        let keys = bindings.chords.keys.sorted(by: Self.herdrKeyOrder)
        var entries: [ShortcutPanel.Entry] = keys.compactMap { key -> ShortcutPanel.Entry? in
            guard let chord = bindings.chords[key] else { return nil }
            return ShortcutPanel.Entry(
                id: key,
                label: title(for: key),
                payload: .chord(expanding(chord, prefix: prefix))
            )
        }
        if bindings.chords["detach"] == nil {
            entries.append(
                ShortcutPanel.Entry(
                    id: "detach",
                    label: title(for: "detach"),
                    payload: .chord("\(prefix), \(ShortcutPanelDefaults.herdrDetachKey)")
                )
            )
        }
        return ShortcutPanel(
            id: "herdr",
            scope: .herdr,
            name: "herdr",
            entries: entries
        )
    }

    private static func prefix(from bindings: MuxKeyBindings?, fallback: String) -> String {
        MuxPrefix.chordText(bindings, fallback: fallback)
    }

    static func expanding(_ chord: String, prefix: String) -> String {
        HerdrChordSyntax.expanding(chord, prefix: prefix)
    }

    static func title(for key: String) -> String {
        let known: [String: String] = [
            "new_tab": "New tab",
            "previous_tab": "Previous tab",
            "next_tab": "Next tab",
            "zoom": "Zoom",
            "workspace_picker": "Workspace picker",
            "new_workspace": "New workspace",
            "detach": "Detach",
        ]
        if let title = known[key] { return title }
        return key.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private static func herdrKeyOrder(_ lhs: String, _ rhs: String) -> Bool {
        let left = herdrActionOrder.firstIndex(of: lhs) ?? herdrActionOrder.count
        let right = herdrActionOrder.firstIndex(of: rhs) ?? herdrActionOrder.count
        if left != right { return left < right }
        return lhs < rhs
    }
}
