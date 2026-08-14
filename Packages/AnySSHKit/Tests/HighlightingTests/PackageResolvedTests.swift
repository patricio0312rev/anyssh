import Foundation
import Testing

private struct ResolvedFile: Decodable {
    struct Pin: Decodable {
        struct State: Decodable {
            let revision: String?
            let branch: String?
        }

        let identity: String
        let state: State
    }

    let pins: [Pin]
}

@Suite struct PackageResolvedTests {
    private static let packageRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private static func pins() throws -> [ResolvedFile.Pin] {
        let url = packageRoot.appending(path: "Package.resolved")
        return try JSONDecoder().decode(ResolvedFile.self, from: Data(contentsOf: url)).pins
    }

    @Test func everyDependencyCarriesAPinnedRevision() throws {
        let pins = try Self.pins()
        #expect(pins.isEmpty == false)

        let hex = CharacterSet(charactersIn: "0123456789abcdef")
        let unpinned = pins.filter { pin in
            guard let revision = pin.state.revision, revision.count >= 40 else { return true }
            return CharacterSet(charactersIn: revision).isSubset(of: hex) == false
        }

        #expect(unpinned.isEmpty, "dependencies without a pinned revision: \(unpinned.map(\.identity))")
    }

    @Test func noDependencyTracksABranch() throws {
        let tracking = try Self.pins().filter { $0.state.branch != nil }
        #expect(tracking.isEmpty, "branch-tracking dependencies: \(tracking.map(\.identity))")
    }
}
