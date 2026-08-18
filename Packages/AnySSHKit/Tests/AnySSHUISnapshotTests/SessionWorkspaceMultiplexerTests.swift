import AnySSHCore
import AnySSHMocks
import Foundation
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionWorkspaceMultiplexerTests {
    @Test func aHerdrCapabilityAnswerReachesTheWorkspaceAsAHerdrAdapter() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        await model.configureMultiplexer(
            for: sessionID,
            connection: connection(answering: Self.herdrAndTmux)
        )

        #expect(model.showsMultiplexer)
        #expect(model.activeMultiplexerAdapter?.kind == .herdr)
    }

    @Test func aTmuxOnlyHostGetsTheTmuxAdapter() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        await model.configureMultiplexer(
            for: sessionID,
            connection: connection(answering: Self.tmuxOnly)
        )

        #expect(model.activeMultiplexerAdapter?.kind == .tmux)
    }

    @Test func aHostWithNeitherToolGetsNoAdapter() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        await model.configureMultiplexer(
            for: sessionID,
            connection: connection(answering: Self.neitherTool)
        )

        #expect(model.activeMultiplexerAdapter == nil)
        #expect(!model.showsMultiplexer)
    }

    @Test func filesAndChangesUseTheActiveHerdrPaneRepo() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        model.replaceMultiplexer(
            for: sessionID,
            with: FixtureMultiplexerAdapter(fixture: .herdrDefault)
        )
        model.registry.setWorkspace(
            WorkspaceLocation(path: "/home/dev", provenance: .process),
            for: sessionID
        )

        await model.resolveWorkspaceForActiveSession()

        #expect(model.activeRecord?.workspace?.path == "/home/dev/src/api")
        #expect(model.activeRecord?.workspace?.provenance == .multiplexer)
    }

    @Test func aHerdrProtocolTheAppCannotReadIsNotAHerdrAdapter() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        await model.configureMultiplexer(
            for: sessionID,
            connection: connection(answering: Self.olderHerdrProtocol)
        )

        #expect(model.activeMultiplexerAdapter?.kind != .herdr)
    }

    private func connection(answering capabilities: String) -> MockRemoteConnection {
        MockRemoteConnection(
            connectionID: ConnectionID(rawValue: "capabilities"),
            script: MockControlScript(sections: ["capabilities": Data(capabilities.utf8)])
        )
    }

    private static func answer(
        tmux: Bool,
        herdrVersion: String,
        herdrProtocol: String
    ) -> String {
        """
        anyssh-capabilities/1
        shell\t/bin/zsh
        platform\tDarwin arm64
        locale\ten_US.UTF-8
        home\t/Users/dev
        path\t/Users/dev/.local/bin:/opt/homebrew/bin:/usr/bin
        git.path\t/opt/homebrew/bin/git
        git.version\tgit version 2.54.0
        tmux.path\t\(tmux ? "/opt/homebrew/bin/tmux" : "")
        tmux.version\t\(tmux ? "tmux 3.6a" : "")
        herdr.path\t\(herdrVersion.isEmpty ? "" : "/Users/dev/.local/bin/herdr")
        herdr.version\t\(herdrVersion)
        herdr.protocol\t\(herdrProtocol)

        """
    }

    private static let supported = String(HerdrReport.supportedProtocolVersion)

    private static let herdrAndTmux = answer(
        tmux: true,
        herdrVersion: "herdr 0.8.0",
        herdrProtocol: supported
    )

    private static let tmuxOnly = answer(tmux: true, herdrVersion: "", herdrProtocol: "")

    private static let neitherTool = answer(tmux: false, herdrVersion: "", herdrProtocol: "")

    private static let olderHerdrProtocol = answer(
        tmux: false,
        herdrVersion: "herdr 0.7.0",
        herdrProtocol: String(HerdrReport.supportedProtocolVersion - 1)
    )
}
