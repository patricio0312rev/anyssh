import AnySSHCore
import Foundation
import SwiftUI
import TerminalEmulator

extension ShortcutPanelsView {
    func entryButton(_ entry: ShortcutPanel.Entry, scope: ShortcutPanel.Scope) -> some View {
        Text(entry.label)
            .font(Theme.code(size: AccessoryBarMetrics.keyFontSize))
            .foregroundStyle(Theme.text.primary)
            .lineLimit(1)
            .padding(.horizontal, Theme.Space.step2)
            .frame(
                minWidth: Theme.Buttons.iconHitTarget,
                minHeight: AccessoryBarMetrics.keyHeight
            )
            .background(
                Theme.surface.raised,
                in: RoundedRectangle(cornerRadius: Theme.Space.controlRadius, style: .continuous)
            )
            .contentShape(
                RoundedRectangle(cornerRadius: Theme.Space.controlRadius, style: .continuous)
            )
            .accessibilityElement()
            .accessibilityLabel(entry.label)
            .accessibilityIdentifier(ShortcutPanelIdentifier.entry(entry, scope: scope))
            .accessibilityAddTraits(.isButton)
            .onTapGesture {
                Task { await model.activate(entry, scope: scope) }
            }
            .onLongPressGesture(minimumDuration: ShortcutPanelMetrics.editPressDuration) {
                editorPresentation = .edit(entry: entry, scope: scope)
            }
    }

    var probe: some View {
        Text(model.renderedLastBytes)
            .font(Theme.Text.caption)
            .frame(height: 1)
            .clipped()
            .opacity(0)
            .accessibilityIdentifier(ShortcutPanelIdentifier.bytes)
    }

    func editor(
        model editorModel: BindingEditorModel,
        entry: ShortcutPanel.Entry,
        scope: ShortcutPanel.Scope
    ) -> some View {
        BindingEditorView(
            model: editorModel,
            onSave: { binding in
                model.save(binding: binding, for: entry, scope: scope)
                editorPresentation = nil
            },
            onCancel: {
                editorPresentation = nil
            }
        )
    }

    func newEntryID() -> String {
        "custom-\(UUID().uuidString.prefix(8))"
    }
}

enum ShortcutPanelMetrics {
    static let editPressDuration = 0.45
}
