#if canImport(UIKit)
import SwiftUI

struct SnippetComposer: View {
    let title: String
    let add: (String, String) -> Void

    @State private var name = ""
    @State private var command = ""

    var body: some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: Theme.Space.step3) {
                    nameField
                    commandField
                }
                .catalogRowChrome()
            } header: {
                SectionLabel(title)
            }
            Section {
                Button("Save", action: save)
                    .buttonStyle(.rowAction)
                    .disabled(command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier(SnippetIdentifier.save)
                    .catalogRowChrome()
            }
        }
    }

    private var nameField: some View {
        HStack {
            label("Name")
            TextField("Optional, defaults to the text", text: $name)
                .foregroundStyle(Theme.text.primary)
                .accessibilityLabel("Name")
                .accessibilityIdentifier(SnippetIdentifier.newTitle)
        }
    }

    private var commandField: some View {
        HStack {
            label("Command")
            TextField("git status -sb", text: $command)
                .font(Theme.code())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(Theme.text.primary)
                .accessibilityLabel("Command")
                .accessibilityIdentifier(SnippetIdentifier.newBody)
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(Theme.Text.body)
            .foregroundStyle(Theme.text.primary)
            .frame(width: FormMetrics.labelWidth, alignment: .leading)
    }

    private func save() {
        add(name, command)
        name = ""
        command = ""
    }
}

#Preview("SnippetComposer") {
    ThemedRoot {
        List {
            SnippetComposer(title: "New snippet") { _, _ in }
        }
        .catalogListSurface()
    }
}
#endif
