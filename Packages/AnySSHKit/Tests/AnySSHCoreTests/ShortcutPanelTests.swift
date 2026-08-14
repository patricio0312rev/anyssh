import AnySSHCore
import Foundation
import Testing

@Suite struct ShortcutPanelTests {
    @Test func fourPanelLayoutRoundTrips() throws {
        let custom = ShortcutPanel(
            id: "custom",
            scope: .custom,
            name: "Custom",
            entries: [ShortcutPanel.Entry(id: "custom-ping", label: "ping", payload: .text("ping"))]
        )
        let layout = ShortcutPanelLayout(panels: [
            ShortcutPanelDefaults.tmux,
            ShortcutPanelDefaults.herdr,
            ShortcutPanelDefaults.agent,
            custom,
        ])

        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try layout.save(to: directory)
        let loaded = ShortcutPanelLayout.load(from: directory)

        #expect(loaded == layout)
        #expect(loaded.scopes == [.tmux, .herdr, .agent, .custom])
        #expect(loaded.panel(scope: .custom)?.entry(id: "custom-ping")?.payload == .text("ping"))
    }

    @Test func corruptFileFallsBackToTheStandardSet() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("not a panel envelope".utf8)
            .write(to: ShortcutPanelLayout.fileURL(in: directory))

        let loaded = ShortcutPanelLayout.load(from: directory)

        #expect(!loaded.panels.isEmpty)
        #expect(loaded.scopes == [.tmux, .herdr, .agent])
    }

    @Test func unknownSchemaVersionFallsBackToTheStandardSet() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data(#"{"schemaVersion": 99, "panels": []}"#.utf8)
            .write(to: ShortcutPanelLayout.fileURL(in: directory))

        let loaded = ShortcutPanelLayout.load(from: directory)

        #expect(loaded.panels == ShortcutPanelDefaults.standard.panels)
    }

    @Test func tmuxPanelIsBuiltFromTheDiscoveredPrefix() {
        let layout = ShortcutPanelBuilder.make(
            kind: .tmux,
            capabilities: capabilities(tmuxPath: "/opt/homebrew/bin/tmux", herdrPath: nil),
            bindings: MuxKeyBindings(prefix: "C-a", chords: [:]),
            persisted: nil
        )

        #expect(layout.contains(scope: .tmux))
        #expect(layout.contains(scope: .herdr) == false)
        #expect(layout.panel(scope: .tmux)?.entry(id: "next-window")?.payload == .chord("C-a, n"))
        #expect(layout.panel(scope: .tmux)?.entry(id: "split-horizontal")?.payload == .chord("C-a, %"))
    }

    @Test func herdrPanelExpandsItsPrefixTokenIntoDiscoveredChords() {
        let layout = ShortcutPanelBuilder.make(
            kind: .herdr,
            capabilities: capabilities(tmuxPath: nil, herdrPath: "/Users/test/.local/bin/herdr"),
            bindings: MuxKeyBindings(prefix: "ctrl+b", chords: ["new_tab": "prefix+t"]),
            persisted: nil
        )

        #expect(layout.contains(scope: .herdr))
        #expect(layout.contains(scope: .tmux) == false)
        #expect(layout.panel(scope: .herdr)?.entry(id: "new_tab")?.payload == .chord("C-b, t"))
        #expect(layout.panel(scope: .herdr)?.entry(id: "new_tab")?.label == "New tab")
    }

    @Test func herdrPanelCarriesDetachEvenWhenTheHostNeverReboundIt() {
        let layout = ShortcutPanelBuilder.make(
            kind: .herdr,
            capabilities: capabilities(tmuxPath: nil, herdrPath: "/Users/test/.local/bin/herdr"),
            bindings: MuxKeyBindings(prefix: "ctrl+b", chords: ["new_tab": "prefix+t"]),
            persisted: nil
        )

        #expect(layout.panel(scope: .herdr)?.entry(id: "detach")?.label == "Detach")
        #expect(layout.panel(scope: .herdr)?.entry(id: "detach")?.payload == .chord("C-b, q"))
    }

    @Test func herdrDetachUsesTheDiscoveredBindingWhenThereIsOne() {
        let layout = ShortcutPanelBuilder.make(
            kind: .herdr,
            capabilities: capabilities(tmuxPath: nil, herdrPath: "/Users/test/.local/bin/herdr"),
            bindings: MuxKeyBindings(
                prefix: "ctrl+a",
                chords: ["new_tab": "prefix+t", "detach": "prefix+shift+d"]
            ),
            persisted: nil
        )

        #expect(layout.panel(scope: .herdr)?.entry(id: "detach")?.payload == .chord("C-a, S-d"))
    }

    @Test func noMultiplexerRemovesBothMuxPanels() {
        let layout = ShortcutPanelBuilder.make(
            kind: .none,
            capabilities: capabilities(tmuxPath: nil, herdrPath: nil),
            bindings: nil,
            persisted: nil
        )

        #expect(layout.contains(scope: .tmux) == false)
        #expect(layout.contains(scope: .herdr) == false)
        #expect(layout.contains(scope: .agent))
        #expect(layout.contains(scope: .custom) == false)
    }

    @Test func theDetectedKindOutranksCapabilities() {
        let layout = ShortcutPanelBuilder.make(
            kind: .tmux,
            capabilities: capabilities(tmuxPath: nil, herdrPath: nil),
            bindings: MuxKeyBindings(prefix: "C-b", chords: [:]),
            persisted: nil
        )

        #expect(layout.contains(scope: .tmux))
    }

    @Test func agentPanelCarriesLiteralTextEntries() {
        let entries = ShortcutPanelDefaults.agent.entries

        #expect(
            entries.map(\.payload) == [
                .text("/clear"),
                .text("/compact"),
                .chord("Esc"),
                .chord("C-c"),
            ])
    }

    @Test func customPanelsSurviveTheRebuild() {
        let custom = ShortcutPanel(
            id: "custom",
            scope: .custom,
            name: "Custom",
            entries: [ShortcutPanel.Entry(id: "custom-ping", label: "ping", payload: .text("ping"))]
        )
        let persisted = ShortcutPanelLayout(panels: [ShortcutPanelDefaults.agent, custom])

        let rebuilt = ShortcutPanelBuilder.make(
            kind: .tmux,
            capabilities: capabilities(tmuxPath: "/opt/homebrew/bin/tmux", herdrPath: nil),
            bindings: MuxKeyBindings(prefix: "C-a", chords: [:]),
            persisted: persisted
        )

        #expect(rebuilt.contains(scope: .custom))
        #expect(rebuilt.panel(scope: .custom)?.entry(id: "custom-ping")?.payload == .text("ping"))
        #expect(rebuilt.panel(scope: .tmux)?.entry(id: "next-window")?.payload == .chord("C-a, n"))
    }

    private func capabilities(tmuxPath: String?, herdrPath: String?) -> HostCapabilities {
        HostCapabilities(
            shell: "/bin/zsh",
            platform: "darwin",
            locale: "en_US.UTF-8",
            home: "/Users/test",
            searchPath: "/opt/homebrew/bin",
            git: ToolReport(path: "/usr/bin/git", version: "2.50.1"),
            tmux: ToolReport(path: tmuxPath, version: tmuxPath == nil ? nil : "3.6a"),
            herdr: HerdrReport(
                tool: ToolReport(path: herdrPath, version: herdrPath == nil ? nil : "0.8.0"),
                protocolVersion: herdrPath == nil ? nil : 19
            )
        )
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "ShortcutPanelTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
