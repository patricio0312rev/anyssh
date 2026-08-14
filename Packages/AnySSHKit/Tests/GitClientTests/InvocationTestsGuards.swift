import Foundation
import Testing

@testable import GitClient

@Suite struct InvocationTestsGuards {
    private static let packageRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private static func swiftSource(under root: URL) throws -> String {
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        else { throw GuardError.unreadable(root) }
        var contents = ""
        for case let file as URL in enumerator where file.pathExtension == "swift" {
            contents += try String(contentsOf: file, encoding: .utf8)
        }
        return contents
    }

    private static func gitClientSource() throws -> String {
        try swiftSource(under: packageRoot.appending(path: "Sources/GitClient"))
    }

    @Test func noCommandIsBuiltByStringInterpolation() throws {
        let source = try Self.gitClientSource()
        #expect(!source.contains("\\("), "git commands must not be assembled by string interpolation")
    }

    @Test func staleStatusAccessorIsGone() throws {
        let source = try Self.gitClientSource()
        let accessor = "status" + "Command"
        #expect(!source.contains(accessor))
    }

    @Test func emptyDiffExternalAssignmentIsAbsentAnywhereInThePackage() throws {
        let forbidden = "-c diff." + "external="
        let roots = [
            Self.packageRoot.appending(path: "Sources"),
            Self.packageRoot.appending(path: "Tests"),
        ]
        for root in roots {
            let source = try Self.swiftSource(under: root)
            #expect(!source.contains(forbidden), "empty diff.external assignment found in source")
        }
    }

    private enum GuardError: Error {
        case unreadable(URL)
    }
}
