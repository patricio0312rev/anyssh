import AnySSHCore
import Foundation
import Testing

@testable import GitClient

@Suite struct MultiFilePatchTests {
    private let patch = """
        diff --git a/one.txt b/one.txt
        index 1111111..2222222 100644
        --- a/one.txt
        +++ b/one.txt
        @@ -1,2 +1,2 @@
         context
        -old line
        +new line
        diff --git a/two.txt b/two.txt
        index 3333333..4444444 100644
        --- a/two.txt
        +++ b/two.txt
        @@ -1,1 +1,2 @@
         kept
        +added
        """

    private func file(_ path: String) -> ChangedFile {
        ChangedFile(oldPath: nil, newPath: path, change: .modified, isBinary: false)
    }

    @Test func aTwoFilePatchIsNotReportedAsTruncated() throws {
        let diff = try DiffParser().parse(Data(patch.utf8), file: file("one.txt"))

        #expect(diff.hunks.count == 2)
        #expect(!diff.truncated)
    }

    @Test func onlyRealChangesAreCounted() throws {
        let diff = try DiffParser().parse(Data(patch.utf8), file: file("one.txt"))
        let lines = diff.hunks.flatMap(\.lines)

        #expect(lines.filter { $0.kind == .addition }.map(\.text) == ["new line", "added"])
        #expect(lines.filter { $0.kind == .deletion }.map(\.text) == ["old line"])
    }

    @Test func aSingleFilePatchStillParses() throws {
        let single = patch.split(separator: "\n").prefix(8).joined(separator: "\n")
        let diff = try DiffParser().parse(Data(single.utf8), file: file("one.txt"))

        #expect(diff.hunks.count == 1)
        #expect(diff.hunks.first?.lines.count == 3)
    }
}
