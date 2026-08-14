#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct SnippetsSheet: View {
    @State private var model: SnippetsModel
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
                        SnippetRow(snippet: snippet)
                    }
                    .buttonStyle(.plain)
                    .catalogRowChrome()
                }
                .onDelete { model.remove($0) }
            }
            SnippetComposer(title: "New snippet") { title, body in
                model.add(title: title, body: body)
            }
        }
        .catalogListSurface()
    }
}
#endif
