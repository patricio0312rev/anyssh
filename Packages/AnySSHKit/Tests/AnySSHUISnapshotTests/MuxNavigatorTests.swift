import AnySSHCore
import AnySSHMocks
import Testing

@testable import AnySSHUI

@Suite struct MuxNavigatorTests {
    private let target = MuxTarget(
        session: MuxSessionID(rawValue: "$1"),
        group: MuxGroupID(rawValue: "@1")
    )

    @Test func anAttachedTerminalIsOnlyFocused() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .attached(nil) }

        #expect(try await navigator.jump(to: target) == .focused)
        #expect(await adapter.focusLog.targets == [target])
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aDetachedTerminalAlsoTypesTheAttachCommand() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .detached }

        #expect(try await navigator.jump(to: target) == .attached)
        #expect(await adapter.focusLog.targets == [target])
        #expect(
            await connection.displayWrites == [
                Array(("'tmux' attach-session -t '$1' \\; select-window -t '@1'\r").utf8)
            ]
        )
    }

    @Test func anUnreadableTerminalIsLeftAlone() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .unknown }

        #expect(try await navigator.jump(to: target) == .focused)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aTerminalBoundToAnotherSessionKeepsItsAttachment() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) {
            .attached(MuxSessionID(rawValue: "$2"))
        }

        #expect(try await navigator.jump(to: target) == .focusedElsewhere(target.session))
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aRefusedFocusNeverReachesTheDisplay() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .absent)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .detached }

        await #expect(throws: ErrorState.mux(.absent)) {
            _ = try await navigator.jump(to: target)
        }
        #expect(await connection.displayWrites.isEmpty)
    }
}
