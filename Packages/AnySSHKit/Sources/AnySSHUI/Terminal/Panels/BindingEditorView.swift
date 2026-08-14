import SwiftUI
import TerminalEmulator

public struct BindingEditorView: View {
    @State private var model: BindingEditorModel

    private let onSave: (SimpleBinding) -> Void
    private let onCancel: () -> Void

    public init(
        model: BindingEditorModel,
        onSave: @escaping (SimpleBinding) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _model = State(wrappedValue: model)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.surface.base.ignoresSafeArea()
                form
            }
            .navigationTitle("Binding")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .accessibilityIdentifier(ShortcutPanelIdentifier.editorCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        Text("Save").foregroundStyle(Theme.accent)
                    }
                    .disabled(!model.canSave)
                    .accessibilityIdentifier(ShortcutPanelIdentifier.editorSave)
                }
            }
        }
        .tint(Theme.accent)
        .accessibilityIdentifier(ShortcutPanelIdentifier.editor)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Keys")
            SurfaceCard {
                chordField
            }
            Text("A chord such as C-b, S-t, or literal text such as b1.")
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
                .padding(.top, Theme.Space.step1)
            SectionLabel("Modifier")
            modifiers
            SectionLabel("Sends")
            SurfaceCard {
                readout
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Space.screenMargin)
    }

    private var chordField: some View {
        TextField("C-b, S-t or b1", text: $model.text)
            .font(Theme.code())
            .autocorrectionDisabled()
            #if canImport(UIKit)
        .textInputAutocapitalization(.never)
            #endif
            .foregroundStyle(Theme.text.primary)
            .accessibilityIdentifier(ShortcutPanelIdentifier.editorText)
    }

    private var modifiers: some View {
        SegmentedPicker(
            options: BindingEditorModel.modifierChoices.map {
                SegmentedPicker.Option(id: $0.id, label: $0.label, value: $0.modifier)
            },
            selection: model.modifier,
            accessibilityIdentifier: { ShortcutPanelIdentifier.modifier($0.id) },
            select: { model.modifier = $0 }
        )
    }

    @ViewBuilder
    private var readout: some View {
        if let preview = model.preview {
            Text(preview)
                .font(Theme.code())
                .foregroundStyle(Theme.text.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier(ShortcutPanelIdentifier.editorPreview)
        } else if let error = model.error {
            Text(error.message)
                .font(Theme.Text.body)
                .foregroundStyle(Theme.status.error)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier(ShortcutPanelIdentifier.editorPreview)
        } else {
            Text("Nothing to send")
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier(ShortcutPanelIdentifier.editorPreview)
        }
    }

    private func save() {
        guard let binding = model.composed else { return }
        onSave(binding)
    }
}
