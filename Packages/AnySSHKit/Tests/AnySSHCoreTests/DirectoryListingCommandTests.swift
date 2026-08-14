import Foundation
import Testing

@testable import AnySSHCore

@Suite struct DirectoryListingCommandTests {
    private func listing(_ records: [String], path: String = "/tmp") -> DirectoryListing {
        let data = records.reduce(into: Data()) { data, record in
            data.append(Data(record.utf8))
            data.append(0)
        }
        return DirectoryListingCommand.parse(data, path: path)
    }

    @Test func kindsComeFromTheHost() {
        let result = listing(["directory\tSources", "file\tREADME.md", "symlink\tcurrent"])

        #expect(result.entries.map(\.name) == ["Sources", "current", "README.md"])
        #expect(result.entries.first?.kind == .directory)
    }

    @Test func foldersLeadAndCaseIsIgnored() {
        let result = listing(["file\tzebra.txt", "file\tApple.txt", "directory\ttests"])

        #expect(result.entries.map(\.name) == ["tests", "Apple.txt", "zebra.txt"])
    }

    @Test func aNameWithANewlineSurvives() {
        let result = listing(["file\tstrange\nname.txt"])

        #expect(result.entries.map(\.name) == ["strange\nname.txt"])
    }

    @Test func aTruncatedListingSaysSo() {
        let result = listing(["file\ta.txt", "truncated"])

        #expect(result.isTruncated)
        #expect(result.entries.count == 1)
    }

    @Test func anUnknownKindIsDropped() {
        #expect(listing(["socket\tdaemon.sock", "file\treal.txt"]).entries.map(\.name) == ["real.txt"])
    }

    @Test func thePathIsQuotedIntoTheScript() {
        let script = DirectoryListingCommand.script(path: "/tmp/it's here", limit: 10)

        #expect(script.contains(#"'/tmp/it'\''s here'"#))
    }
}
