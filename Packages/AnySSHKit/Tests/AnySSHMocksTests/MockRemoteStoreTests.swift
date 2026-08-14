import Testing

@testable import AnySSHMocks

@Suite struct MockRemoteStoreTests {
    @Test func theEmptyScenarioYieldsNoRemotes() async throws {
        #expect(try await MockRemoteStore(scenario: "empty").remotes().isEmpty)
    }

    @Test func theDefaultScenarioIsStable() async throws {
        let remotes = try await MockRemoteStore(scenario: "default").remotes()
        #expect(remotes.map(\.name) == ["Workstation", "Build Box", "Edge Node"])
    }
}
