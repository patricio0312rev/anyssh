import AnySSHCore
import Foundation
import Testing

@testable import GitClient

@Suite struct UpstreamParsingTests {
    private func status(_ records: [String]) throws -> RepositoryStatus {
        let data = records.reduce(into: Data()) { data, record in
            data.append(Data(record.utf8))
            data.append(0)
        }
        return try StatusParser().parse(data)
    }

    @Test func theUpstreamKeepsItsWholeName() throws {
        let result = try status([
            "# branch.oid abc123",
            "# branch.head main",
            "# branch.upstream origin/main",
            "# branch.ab +0 -0",
        ])

        #expect(result.upstream?.name == "origin/main")
    }

    @Test func aheadAndBehindAreRead() throws {
        let result = try status([
            "# branch.oid abc123",
            "# branch.head main",
            "# branch.upstream origin/main",
            "# branch.ab +2 -3",
        ])

        #expect(result.upstream?.ahead == 2)
        #expect(result.upstream?.behind == 3)
    }

    @Test func aBranchWithNoUpstreamHasNone() throws {
        let result = try status(["# branch.oid abc123", "# branch.head local-only"])

        #expect(result.upstream == nil)
    }
}
