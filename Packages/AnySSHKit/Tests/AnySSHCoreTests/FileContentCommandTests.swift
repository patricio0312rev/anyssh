import Foundation
import Testing

@testable import AnySSHCore

@Suite struct FileContentCommandTests {
    private func response(size: Int, body: Data) -> Data {
        Data("size\t\(size)\ncontent\n".utf8) + body
    }

    @Test func contentAndSizeAreReadBack() throws {
        let content = try FileContentCommand.parse(response(size: 5, body: Data("hello".utf8)))

        #expect(content.bytes == Data("hello".utf8))
        #expect(content.byteCount == 5)
        #expect(!content.isTruncated)
    }

    @Test func aCappedReadKnowsItWasCut() throws {
        let content = try FileContentCommand.parse(response(size: 900_000, body: Data("head".utf8)))

        #expect(content.isTruncated)
    }

    @Test func aNulInTheHeadMeansBinary() throws {
        let content = try FileContentCommand.parse(
            response(size: 4, body: Data([0x89, 0x50, 0x00, 0x47]))
        )

        #expect(content.isBinary)
    }

    @Test func contentContainingTheMarkerIsNotRefrained() throws {
        let body = Data("content\nmore\n".utf8)
        let content = try FileContentCommand.parse(response(size: body.count, body: body))

        #expect(content.bytes == body)
    }

    @Test func aDirectoryIsRefused() {
        #expect(throws: FileContentCommand.Failure.notAFile) {
            try FileContentCommand.parse(Data("error\tnot-a-file\n".utf8))
        }
    }

    @Test func thePathIsQuotedIntoTheScript() {
        #expect(FileContentCommand.script(path: "/a b/c'd", cap: 10).contains(#"'/a b/c'\''d'"#))
    }
}
