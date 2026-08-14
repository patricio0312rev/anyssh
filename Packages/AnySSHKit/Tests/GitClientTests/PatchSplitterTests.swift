import AnySSHCore
import Foundation
import Testing

@testable import GitClient

@Suite struct PatchSplitterTests {
    @Test func eachFileBecomesItsOwnSegment() {
        let patch = """
            diff --git a/one.txt b/one.txt
            --- a/one.txt
            +++ b/one.txt
            @@ -1 +1 @@
            -old
            +new
            diff --git a/two.txt b/two.txt
            --- a/two.txt
            +++ b/two.txt
            @@ -1 +1 @@
            -x
            +y
            """

        let segments = PatchSplitter.split(Data(patch.utf8))

        #expect(segments.map { $0.file.newPath } == ["one.txt", "two.txt"])
        #expect(segments.first?.patch.isEmpty == false)
    }

    @Test func aCreatedFileHasNoOldPath() {
        let patch = """
            diff --git a/new.txt b/new.txt
            --- /dev/null
            +++ b/new.txt
            @@ -0,0 +1 @@
            +hello
            """

        let segment = PatchSplitter.split(Data(patch.utf8)).first

        #expect(segment?.file.oldPath == nil)
        #expect(segment?.file.newPath == "new.txt")
        #expect(segment?.file.change == .added)
    }

    @Test func aDeletedFileHasNoNewPath() {
        let patch = """
            diff --git a/gone.txt b/gone.txt
            --- a/gone.txt
            +++ /dev/null
            @@ -1 +0,0 @@
            -bye
            """

        let segment = PatchSplitter.split(Data(patch.utf8)).first

        #expect(segment?.file.newPath == nil)
        #expect(segment?.file.change == .deleted)
    }

    @Test func eachSegmentParsesOnItsOwn() throws {
        let patch = """
            diff --git a/one.txt b/one.txt
            --- a/one.txt
            +++ b/one.txt
            @@ -1,2 +1,2 @@
             kept
            -old
            +new
            diff --git a/two.txt b/two.txt
            --- a/two.txt
            +++ b/two.txt
            @@ -1 +1,2 @@
             kept
            +added
            """

        let diffs = PatchSplitter.split(Data(patch.utf8)).compactMap {
            try? DiffParser().parse($0.patch, file: $0.file)
        }

        #expect(diffs.count == 2)
        #expect(diffs.allSatisfy { !$0.truncated })
        #expect(diffs.flatMap(\.hunks).flatMap(\.lines).filter { $0.kind == .addition }.count == 2)
    }
}

@Suite struct PatchSegmentCountTests {
    @Test func linesAreCountedPerFile() {
        let patch = """
            diff --git a/one.txt b/one.txt
            --- a/one.txt
            +++ b/one.txt
            @@ -1,3 +1,3 @@
             kept
            -old
            +new
            +extra
            diff --git a/two.txt b/two.txt
            --- a/two.txt
            +++ b/two.txt
            @@ -1,2 +1,1 @@
             kept
            -gone
            """

        let segments = PatchSplitter.split(Data(patch.utf8))

        #expect(segments.first?.file.additions == 2)
        #expect(segments.first?.file.deletions == 1)
        #expect(segments.last?.file.additions == 0)
        #expect(segments.last?.file.deletions == 1)
    }

    @Test func fileHeadersAreNotCounted() {
        let patch = """
            diff --git a/one.txt b/one.txt
            index 111..222 100644
            --- a/one.txt
            +++ b/one.txt
            @@ -1 +1 @@
            -old
            +new
            """

        let segment = PatchSplitter.split(Data(patch.utf8)).first

        #expect(segment?.file.additions == 1)
        #expect(segment?.file.deletions == 1)
    }
}
