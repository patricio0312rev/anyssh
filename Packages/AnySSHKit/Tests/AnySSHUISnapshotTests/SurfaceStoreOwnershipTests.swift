import Foundation
import Testing

@Suite struct SurfaceStoreOwnershipTests {
    @Test func noViewFileNamesTheSurfaceStore() throws {
        let views = try Self.viewFiles()

        #expect(!views.isEmpty)
        for url in views {
            let source = try String(contentsOf: url, encoding: .utf8)
            #expect(
                !source.contains("TerminalSurfaceStore"),
                "\(url.lastPathComponent) reaches the surface store from a view"
            )
        }
    }

    private static func viewFiles() throws -> [URL] {
        let root = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/AnySSHUI")
        let manager = FileManager.default
        try #require(manager.fileExists(atPath: root.path(percentEncoded: false)))

        guard let walker = manager.enumerator(at: root, includingPropertiesForKeys: nil) else {
            return []
        }
        return walker.compactMap { $0 as? URL }.filter { $0.lastPathComponent.hasSuffix("View.swift") }
    }
}
