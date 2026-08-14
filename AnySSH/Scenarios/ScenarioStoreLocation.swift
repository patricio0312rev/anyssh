import AnySSHCore
import Foundation

enum ScenarioStoreLocation {
    static let root = URL.temporaryDirectory.appending(path: "anyssh-scenarios")

    static var snippets: URL {
        root.appending(path: "snippets.json")
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
