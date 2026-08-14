import CSSH
import Foundation
import Testing

@testable import SSHTransport

@Suite struct LibSSH2SmokeTests {
    @Test func libraryReportsItsVersion() {
        let version = LibSSH2.version
        #expect(version.hasPrefix("1."))
        #expect(libssh2_version(0x01_0b_00) != nil)
    }

    @Test func libraryInitialisesAndShutsDown() throws {
        let session = try LibSSH2.withLibrary { libssh2_session_init_ex(nil, nil, nil, nil) }
        #expect(session != nil)
        if let session { libssh2_session_free(session) }
    }
}

@Suite(.enabled(if: LiveHost.isDevelopmentHostReachable))
struct LiveHostSmokeTests {
    @Test func execChannelRoundTripsOverAPublickeySession() throws {
        let outcome = try LiveSSHProbe(host: .development).run(command: "echo ANYSSH_OK")

        #expect(outcome.output.trimmingCharacters(in: .whitespacesAndNewlines) == "ANYSSH_OK")
        #expect(outcome.exitStatus == 0)
    }

    @Test func negotiatedHostKeyIsReadable() throws {
        let outcome = try LiveSSHProbe(host: .development).run(command: "true")

        #expect(outcome.hostKeyByteCount > 0)
        #expect(outcome.hostKeyFingerprint.count == 64)
        #expect(outcome.hostKeyType != LIBSSH2_HOSTKEY_TYPE_UNKNOWN)
    }
}
