import Testing

@testable import SSHTransport

@Suite(.enabled(if: LiveHost.isDevelopmentHostReachable))
struct LoginShellRegressionTests {
    @Test func bareExecAndLoginShellResolveGitDifferently() async throws {
        let bare = try await LiveSetupRetry.run { try runLiveCapabilityProbe(loginShell: false) }
        let login = try await LiveSetupRetry.run { try runLiveCapabilityProbe(loginShell: true) }

        #expect(bare.git.path != login.git.path)
    }
}
