import AnySSHCore
import AnySSHMocks
import AnySSHUI
import Sessions
import SwiftUI

struct SessionsScenarioView: View {
    let scenario: SessionsScenario

    var body: some View {
        surface.tint(Theme.accent)
    }

    @ViewBuilder
    private var surface: some View {
        switch scenario {
        case .switcherList:
            SessionSwitcherView(model: ScenarioSessionSwitcher(fixture: "four")) { _ in }
        case .switcherGrid:
            SessionSwitcherView(
                model: ScenarioSessionSwitcher(fixture: "four", isGridMode: true)
            ) { _ in }
        case .switcherEmpty:
            SessionSwitcherView(model: ScenarioSessionSwitcher(fixture: "empty")) { _ in }
        case .reconnect:
            SessionsReconnectScenario(failure: nil)
        case .reconnectFailure:
            SessionsReconnectScenario(failure: .transport(.connectionRefused))
        case .palette:
            CommandPaletteView(
                entries: PaletteScenarioEntries.all,
                onActivate: { _ in },
                onDismiss: {}
            )
        case .paletteEmpty:
            CommandPaletteView(
                entries: PaletteScenarioEntries.all,
                initialQuery: "zzz",
                onActivate: { _ in },
                onDismiss: {}
            )
        case .jumpTo:
            JumpToSheet(model: jumpModel(.herdrDefault, layout: .list), onDismiss: {})
        case .jumpToGrid:
            JumpToSheet(model: jumpModel(.herdrDefault, layout: .grid), onDismiss: {})
        case .jumpToTmux:
            JumpToSheet(model: jumpModel(.tmuxMain, layout: .list), onDismiss: {})
        case .panes:
            MultiplexerPaneListView(adapter: FixtureMultiplexerAdapter(fixture: .herdrDefault))
        case .panels:
            SessionsPanelsScenario()
        case .bindingEditor:
            BindingEditorView(
                model: BindingEditorModel(text: "C-b, S-t"),
                onSave: { _ in },
                onCancel: {}
            )
        case .snippets:
            SnippetsSheet(store: SnippetStore(fileURL: ScenarioStoreLocation.snippets)) { _ in }
        }
    }

    private func jumpModel(_ fixture: MuxFixture, layout: JumpLayout) -> JumpToModel {
        JumpToModel(
            adapter: FixtureMultiplexerAdapter(fixture: fixture),
            directory: ScenarioStoreLocation.jumpLayout(layout),
            writer: nil
        )
    }
}
