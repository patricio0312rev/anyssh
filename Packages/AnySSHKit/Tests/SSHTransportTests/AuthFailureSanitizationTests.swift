import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite struct AuthFailureSanitizationTests {
    @Test func stripsControlCharactersAndBoundsTheDetail() {
        let hostile = "rejected\u{1B}[2J\nline\ttab\u{0}nul" + String(repeating: "A", count: 500)

        let failure = AuthFailure.from(
            code: 42, message: hostile, method: .password, encrypted: false)

        #expect(failure.detail.count <= AuthFailure.detailLimit)
        #expect(!failure.detail.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) })
        #expect(failure.detail.hasPrefix("rejected[2Jlinetabnul"))
        #expect(failure.code == 42)
        #expect(failure.stateID == AuthFailure.passwordRejected.stateID)
    }

    @Test func trimsSurroundingWhitespaceLeftByStripping() {
        let failure = AuthFailure.from(
            code: 1, message: "\r\n  spaced  \r\n", method: .password, encrypted: false)

        #expect(failure.detail == "spaced")
    }
}
