import Foundation

enum LiveArtifact {
    static func write(_ name: String, _ contents: [String: Any]) throws {
        let directory = repositoryRoot().appending(path: ".build/artifacts")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let data = try JSONSerialization.data(
            withJSONObject: contents,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: directory.appending(path: name), options: .atomic)
    }

    private static func repositoryRoot() -> URL {
        var url = URL(filePath: #filePath)
        for _ in 0..<6 { url = url.deletingLastPathComponent() }
        return url
    }
}
