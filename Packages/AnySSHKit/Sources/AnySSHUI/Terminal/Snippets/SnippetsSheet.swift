#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct SnippetsSheet: View {
    @State private var model: SnippetsModel
    @State private var newTitle = ""
    @State private var newBody = ""
    @Environment(\.dismiss) private var dismiss

    private let insert: (String) -> Void

    public init(store: SnippetStore = .applicationSupport(), insert: @escaping (String) -> Void) {
        _model = State(wrappedValue: SnippetsModel(store: store))
        self.insert = insert
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.surface.base.ignoresSafeArea()
                list
            }
            .navigationTitle("Snippets")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(accessibilityIdentifier: SnippetIdentifier.close) { dismiss() }
                }
            }
        }
        .tint(Theme.accent)
        .accessibilityIdentifier(SnippetIdentifier.sheet)
    }

    private var list: some View {
        List {
            Section {
                ForEach(model.library.snippets) { snippet in
                    Button {
                        insert(snippet.body)
                        dismiss()
                    } label: {
                        CatalogRow(
                            title: snippet.label,
                            subtitle: snippet.title.isEmpty ? nil : snippet.body,
                            subtitleMonospaced: true,
                            accessibilityIdentifier: SnippetIdentifier.row(snippet.id),
                            leading: {
                                RowIconTile(
                                    systemImage: "chevron.left.forwardslash.chevron.right",
                                    label: "Snippet"
                                )
                            },
                            trailing: { EmptyView() },
                            footer: { EmptyView() }
                        )
                    }
                    .buttonStyle(.plain)
                    .catalogRowChrome()
                }
                .onDelete { model.remove($0) }
            }
            Section {
                newSnippetCard
            } header: {
                SectionLabel("New snippet")
            }
        }
        .catalogListSurface()
    }

    private var newSnippetCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step3) {
            TextField("Name", text: $newTitle)
                .foregroundStyle(Theme.text.primary)
                .accessibilityIdentifier(SnippetIdentifier.newTitle)
            TextField("Command", text: $newBody)
                .font(Theme.code())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(Theme.text.primary)
                .accessibilityIdentifier(SnippetIdentifier.newBody)
            Button("Save") {
                model.add(title: newTitle, body: newBody)
                newTitle = ""
                newBody = ""
            }
            .buttonStyle(.rowAction)
            .disabled(newBody.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityIdentifier(SnippetIdentifier.save)
        }
        .catalogRowChrome()
    }
}
#endif
