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
            ScenarioSheet { dismiss in
                JumpToSheet(model: jumpModel(.herdrDefault, layout: .list), onDismiss: dismiss)
            }
        case .jumpToGrid:
            ScenarioSheet { dismiss in
                JumpToSheet(model: jumpModel(.herdrDefault, layout: .grid), onDismiss: dismiss)
            }
        case .jumpToTmux:
            ScenarioSheet { dismiss in
                JumpToSheet(model: jumpModel(.tmuxMain, layout: .list), onDismiss: dismiss)
            }
        case .jumpToJumped:
            ScenarioSheet { dismiss in
                JumpToSheet(
                    model: jumpModel(.herdrDefault, layout: .list, writer: MockRemoteConnection()),
                    onDismiss: dismiss
                )
            }
        case .panes:
            ScenarioSheet { dismiss in
                MultiplexerPaneListView(
                    adapter: FixtureMultiplexerAdapter(fixture: .herdrDefault),
                    writer: MockRemoteConnection(),
                    onDismiss: dismiss
                )
            }
        case .panels:
            SessionsPanelsScenario()
        case .bindingEditor:
            BindingEditorView(
                model: BindingEditorModel(text: "C-b, S-t"),
                onSave: { _ in },
                onCancel: {}
            )
        case .snippets:
            ScenarioSheet { _ in
                SnippetsSheet(store: SnippetStore(fileURL: ScenarioStoreLocation.snippets)) { _ in }
            }
        }
    }

    private func jumpModel(
        _ fixture: MuxFixture,
        layout: JumpLayout,
        writer: (any DisplayWriter)? = nil
    ) -> JumpToModel {
        JumpToModel(
            adapter: FixtureMultiplexerAdapter(fixture: fixture),
            directory: ScenarioStoreLocation.jumpLayout(layout),
            writer: writer
        )
    }
}
