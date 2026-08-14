import AnySSHCore
import Foundation
import Observation

@MainActor
@Observable
public final class SnippetsModel {
    public private(set) var library: SnippetLibrary
    private let store: SnippetStore

    public init(store: SnippetStore = .applicationSupport()) {
        self.store = store
        library = store.load()
    }

    public func add(title: String, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        library.snippets.append(Snippet(title: title, body: trimmed))
        try? store.save(library)
    }

    public func remove(_ offsets: IndexSet) {
        library.snippets.remove(atOffsets: offsets)
        try? store.save(library)
    }
}
