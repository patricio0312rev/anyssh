import AnySSHCore
import Foundation
import Testing

@testable import GitClient

@Suite struct DiffParserHostileTests {
    private let file = ChangedFile(
        oldPath: nil, newPath: "Sources/App.swift", change: .modified, isBinary: false
    )

    private func parse(_ payload: String) throws -> FileDiff {
        try DiffParser().parse(Data(payload.utf8), file: file)
    }

    @Test func emptyHunkBoundsDoNotTrap() throws {
        let diff = try parse("@@ @@\n")
        #expect(diff.hunks.isEmpty)
    }

    @Test func signOnlyHunkFieldDoesNotTrap() throws {
        let diff = try parse("@@ - @@\n")
        #expect(diff.hunks.isEmpty)
    }

    @Test func bareMarkerIsNotAHeader() throws {
        let diff = try parse("@@\n")
        #expect(diff.hunks.isEmpty)
    }

    @Test func emptyHunkRangeDoesNotTrap() throws {
        let diff = try parse("@@  @@\n")
        #expect(diff.hunks.isEmpty)
    }

    @Test func aValidHeaderStillParses() throws {
        let payload = "@@ -1,1 +1,2 @@ func main\n context\n+added\n"
        let diff = try parse(payload)
        #expect(diff.hunks.count == 1)
        #expect(diff.hunks.first?.oldStart == 1)
        #expect(diff.hunks.first?.newCount == 2)
        #expect(diff.hunks.first?.heading == " func main")
    }
}
