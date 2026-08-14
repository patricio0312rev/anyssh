import Foundation
import Testing

@testable import FileTransfer

@Suite struct VerificationParserTests {
    private let digest = String(repeating: "a1b2c3d4", count: 8)

    @Test func readsACleanAnswer() throws {
        let result = try VerificationParser.parse(
            Data("42\n\(digest)  /home/me/shot.png\n".utf8),
            path: "/home/me/shot.png"
        )

        #expect(result.byteCount == 42)
        #expect(result.sha256 == digest)
    }

    @Test func readsPastACommandThatDoesNotExist() throws {
        let output = "42\nsh: sha256sum: command not found\n\(digest)  shot.png\n"
        let result = try VerificationParser.parse(Data(output.utf8), path: "shot.png")

        #expect(result.byteCount == 42)
        #expect(result.sha256 == digest)
    }

    @Test func readsPastALoginBanner() throws {
        let output = "Welcome to build-box\nLast login: Tue\n7\n\(digest) shot.png\n"
        let result = try VerificationParser.parse(Data(output.utf8), path: "shot.png")

        #expect(result.byteCount == 7)
        #expect(result.sha256 == digest)
    }

    @Test func refusesWhenNoDigestIsThere() {
        #expect(throws: UploadError.verificationFailed) {
            try VerificationParser.parse(Data("42\nnothing here\n".utf8), path: "shot.png")
        }
    }
}
