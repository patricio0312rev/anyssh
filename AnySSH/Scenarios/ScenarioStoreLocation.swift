import AnySSHCore
import Foundation

enum ScenarioStoreLocation {
    static let root = URL.temporaryDirectory.appending(path: "anyssh-scenarios")

    static var snippets: URL {
        root.appending(path: "snippets.json")
    }

    static var gestures: URL {
        directory(named: "gestures")
    }

    static func emptySnippets() -> SnippetStore {
        let store = SnippetStore(fileURL: root.appending(path: "snippets-empty.json"))
        try? store.save(SnippetLibrary(snippets: []))
        return store
    }

    static func seededSnippets() -> SnippetStore {
        let store = SnippetStore(fileURL: root.appending(path: "snippets-seeded.json"))
        try? store.save(
            SnippetLibrary(snippets: [
                Snippet(title: "Tail the log", body: "tail -f /var/log/syslog"),
                Snippet(title: "", body: "git status --short"),
                Snippet(title: "Restart the service", body: "sudo systemctl restart anyssh"),
            ])
        )
        return store
    }

    static var panels: URL {
        directory(named: "panels")
    }

    static func jumpLayout(_ layout: JumpLayout) -> URL {
        let url = directory(named: "jump-\(layout.rawValue)")
        JumpLayoutPreference.save(layout, to: url)
        return url
    }

    private static func directory(named name: String) -> URL {
        let url = root.appending(path: name)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
