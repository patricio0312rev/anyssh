import Testing

@testable import Sessions

@Suite struct StartDirectoryPolicyTests {
    @Test func aConfiguredPathBeatsARememberedOne() {
        #expect(
            StartDirectoryPolicy.path(remembered: "/Users/dev", configured: "~/Sites/anyssh")
                == "~/Sites/anyssh"
        )
    }

    @Test func theRememberedPathIsUsedWhenNothingIsConfigured() {
        #expect(
            StartDirectoryPolicy.path(remembered: "/home/ci/work", configured: nil) == "/home/ci/work"
        )
    }

    @Test func aBlankConfiguredPathFallsBackToWhereYouWere() {
        #expect(
            StartDirectoryPolicy.path(remembered: "/home/ci/work", configured: "   ") == "/home/ci/work"
        )
    }

    @Test func homeIsNotAnAnswer() {
        #expect(StartDirectoryPolicy.path(remembered: "~", configured: nil) == nil)
        #expect(StartDirectoryPolicy.path(remembered: nil, configured: nil) == nil)
    }
}
