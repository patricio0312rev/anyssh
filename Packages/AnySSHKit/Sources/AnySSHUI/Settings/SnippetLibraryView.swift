#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct SnippetLibraryView: View {
    @State private var model: SnippetsModel

    public init(store: SnippetStore = .applicationSupport()) {
        _model = State(wrappedValue: SnippetsModel(store: store))
    }

    public var body: some View {
        List {
            saved
            composer
        }
        .catalogListSurface()
        .navigationTitle("Saved commands")
        .accessibilityIdentifier(UIIdentifier.Settings.snippetsScreen)
    }

    private var saved: some View {
        Section {
            if model.library.snippets.isEmpty {
                Text("Nothing saved yet.")
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .catalogRowChrome()
            }
            ForEach(model.library.snippets) { snippet in
                SnippetRow(snippet: snippet)
                    .catalogRowChrome()
            }
            .onDelete { model.remove($0) }
        } header: {
            SectionLabel("Saved")
        } footer: {
            if !model.library.snippets.isEmpty {
                SectionCaption(
                    "Swipe a command to delete it. The terminal inserts them from its snippets "
                        + "sheet."
                )
            }
        }
    }

    private var composer: some View {
        SnippetComposer(title: "New command") { title, body in
            model.add(title: title, body: body)
        }
    }
}

#Preview("SnippetLibraryView") {
    ThemedRoot {
        NavigationStack {
            SnippetLibraryView(
                store: SnippetStore(fileURL: URL.temporaryDirectory.appending(path: "snips.json"))
            )
        }
    }
}
#endif
