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

    @Test func aSessionJumpToTheBoundSessionDoesNothing() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) {
            .attached(MuxSessionID(rawValue: "$1"))
        }

        let outcome = try await navigator.jump(toSession: MuxSessionID(rawValue: "$1"), from: nil)

        #expect(outcome == .focused)
        #expect(await adapter.switchLog.switches.isEmpty)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aSessionJumpOnAnAttachedTerminalSwitchesTheClient() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) {
            .attached(MuxSessionID(rawValue: "$1"))
        }

        let outcome = try await navigator.jump(toSession: MuxSessionID(rawValue: "$2"), from: nil)

        #expect(outcome == .attached)
        #expect(
            await adapter.switchLog.switches == [
                MuxSessionSwitch(
                    target: MuxSessionID(rawValue: "$2"),
                    source: MuxSessionID(rawValue: "$1")
                )
            ]
        )
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func anAttachedTerminalWithNoBindingSkipsTheSession() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .attached(nil) }

        let outcome = try await navigator.jump(toSession: MuxSessionID(rawValue: "$2"), from: nil)

        #expect(outcome == .skipped(MuxSessionID(rawValue: "$2")))
        #expect(await adapter.switchLog.switches.isEmpty)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aRefusedSwitchOnAnAttachedTerminalSkipsTheSession() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .herdrDefault)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) {
            .attached(MuxSessionID(rawValue: "default"))
        }

        let outcome = try await navigator.jump(
            toSession: MuxSessionID(rawValue: "review"),
            from: nil
        )

        #expect(outcome == .skipped(MuxSessionID(rawValue: "review")))
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aDetachedTerminalTypesTheSessionAttachCommand() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .detached }

        let outcome = try await navigator.jump(toSession: MuxSessionID(rawValue: "$2"), from: nil)

        #expect(outcome == .attached)
        #expect(await adapter.switchLog.switches.isEmpty)
        #expect(
            await connection.displayWrites == [
                Array(("'tmux' attach-session -t '$2'\r").utf8)
            ]
        )
    }

    @Test func anUnknownAttachmentNeverTypesAndFallsBackToTheSwitch() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .unknown }

        let outcome = try await navigator.jump(
            toSession: MuxSessionID(rawValue: "$2"),
            from: MuxSessionID(rawValue: "$1")
        )

        #expect(outcome == .attached)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func anUnknownAttachmentWithARefusedSwitchIsLeftAlone() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .herdrDefault)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .unknown }

        let outcome = try await navigator.jump(
            toSession: MuxSessionID(rawValue: "review"),
            from: MuxSessionID(rawValue: "default")
        )

        #expect(outcome == .focused)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func anUnknownAttachmentWithNoBindingNeverTypes() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .unknown }

        let outcome = try await navigator.jump(toSession: MuxSessionID(rawValue: "$2"), from: nil)

        #expect(outcome == .focused)
        #expect(await adapter.switchLog.switches.isEmpty)
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
