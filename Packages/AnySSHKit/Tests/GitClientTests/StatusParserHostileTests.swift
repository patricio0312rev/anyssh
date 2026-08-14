import AnySSHCore
import Foundation
import Testing

@testable import GitClient

@Suite struct StatusParserHostileTests {
    private func parse(_ payload: String) throws -> RepositoryStatus {
        try StatusParser().parse(Data(payload.utf8))
    }

    @Test func bareKindMarkerThrows() {
        #expect(throws: GitParserError.self) {
            _ = try parse("1")
        }
    }

    @Test func bareKindMarkerWithNulThrows() {
        #expect(throws: GitParserError.self) {
            _ = try parse("1\0")
        }
    }

    @Test func recordMissingXYFieldThrows() {
        let payload = "# branch.oid abc123\0# branch.head main\01\0"
        #expect(throws: GitParserError.self) {
            _ = try parse(payload)
        }
    }

    @Test func aWellFormedRecordStillParses() throws {
        let payload =
            "# branch.head main\0"
            + "1 M. N... 100644 100644 100644 "
            + "1111111 2222222 Sources/App.swift\0"
        let status = try parse(payload)
        #expect(status.staged.count == 1)
        #expect(status.staged.first?.newPath == "Sources/App.swift")
    }
}
