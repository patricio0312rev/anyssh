import Foundation

public struct SnippetStore: Sendable {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func applicationSupport() -> SnippetStore {
        SnippetStore(fileURL: AppDirectories.support.appending(path: "snippets.json"))
    }

    public func load() -> SnippetLibrary {
        guard let data = try? Data(contentsOf: fileURL),
            let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
            envelope.schemaVersion == SnippetLibrary.schemaVersion
        else {
            return SnippetLibrary()
        }
        return SnippetLibrary(snippets: envelope.snippets)
    }

    public func save(_ library: SnippetLibrary) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(
            Envelope(schemaVersion: SnippetLibrary.schemaVersion, snippets: library.snippets)
        )
        try data.write(to: fileURL, options: .atomic)
    }

    private struct Envelope: Codable {
        let schemaVersion: Int
        let snippets: [Snippet]
    }
}
