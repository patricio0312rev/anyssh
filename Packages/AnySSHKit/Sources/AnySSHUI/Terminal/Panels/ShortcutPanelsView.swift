import AnySSHCore
import Foundation
import SwiftUI
import TerminalEmulator

public struct ShortcutPanelsView: View {
    @State var model: ShortcutPanelsModel
    @State var editorPresentation: EditorPresentation?

    public init(
        layout: ShortcutPanelLayout = ShortcutPanelDefaults.standard,
        kind: MultiplexerKind = .none,
        capabilities: HostCapabilities? = nil,
        bindings: MuxKeyBindings? = nil,
        directory: URL? = nil,
        writer: (any DisplayWriter)? = nil,
        onDetach: (@MainActor (ShortcutPanelsModel.DetachOutcome) -> Void)? = nil
    ) {
        let model = ShortcutPanelsModel(
            layout: layout,
            kind: kind,
            capabilities: capabilities,
            bindings: bindings,
            directory: directory,
            writer: writer
        )
        model.onDetach = onDetach
        _model = State(wrappedValue: model)
    }

    public init(
        directory: URL,
        kind: MultiplexerKind = .none,
        capabilities: HostCapabilities? = nil,
        bindings: MuxKeyBindings? = nil,
        writer: (any DisplayWriter)? = nil,
        onDetach: (@MainActor (ShortcutPanelsModel.DetachOutcome) -> Void)? = nil
    ) {
        let model = ShortcutPanelsModel(
            directory: directory,
            kind: kind,
            capabilities: capabilities,
            bindings: bindings,
            writer: writer
        )
        model.onDetach = onDetach
        _model = State(wrappedValue: model)
    }

    public init(
        remoteStoreLocation: URL,
        kind: MultiplexerKind = .none,
        capabilities: HostCapabilities? = nil,
        bindings: MuxKeyBindings? = nil,
        writer: (any DisplayWriter)? = nil,
        onDetach: (@MainActor (ShortcutPanelsModel.DetachOutcome) -> Void)? = nil
    ) {
        let model = ShortcutPanelsModel(
            remoteStoreLocation: remoteStoreLocation,
            kind: kind,
            capabilities: capabilities,
            bindings: bindings,
            writer: writer
        )
        model.onDetach = onDetach
        _model = State(wrappedValue: model)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step2) {
            tabs
            if let panel = model.selectedPanel {
                entries(panel)
            }
            probe
        }
        .padding(.horizontal, Theme.Space.step2)
        .padding(.vertical, Theme.Space.step2)
        .glassEffect(.regular, in: .rect)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.separator)
                .frame(height: AccessoryBarMetrics.hairline)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(ShortcutPanelIdentifier.bar)
        .sheet(item: $editorPresentation) { presentation in
            editorSheet(presentation)
        }
    }

    private var tabs: some View {
        HStack(spacing: Theme.Space.step2) {
            SegmentedPicker(
                options: model.layout.panels.map {
                    SegmentedPicker.Option(id: $0.id, label: $0.name, value: $0.scope)
                },
                selection: model.selectedScope,
                accessibilityIdentifier: { ShortcutPanelIdentifier.tab($0.value) },
                select: { model.select($0) }
            )
            IconButton(
                systemImage: "plus",
                label: "Add custom entry",
                surface: .raised,
                accessibilityIdentifier: ShortcutPanelIdentifier.addCustomEntry
            ) {
                model.addCustomPanel()
                editorPresentation = .newEntry(scope: .custom)
            }
            Spacer(minLength: 0)
        }
    }

    private func entries(_ panel: ShortcutPanel) -> some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: Theme.Space.step2) {
                ForEach(panel.entries) { entry in
                    entryButton(entry, scope: panel.scope)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .accessibilityIdentifier(ShortcutPanelIdentifier.panel(panel.scope))
    }

    @ViewBuilder
    private func editorSheet(_ presentation: EditorPresentation) -> some View {
        switch presentation {
        case .edit(let entry, let scope):
            editor(
                model: BindingEditorModel(payload: entry.payload),
                entry: entry,
                scope: scope
            )
        case .newEntry(let scope):
            editor(
                model: BindingEditorModel(),
                entry: ShortcutPanel.Entry(id: newEntryID(), label: "", payload: .text("")),
                scope: scope
            )
        }
    }
}

enum EditorPresentation: Identifiable {
    case edit(entry: ShortcutPanel.Entry, scope: ShortcutPanel.Scope)
    case newEntry(scope: ShortcutPanel.Scope)

    var id: String {
        switch self {
        case .edit(let entry, _): entry.id
        case .newEntry: "new-entry"
        }
    }
}
