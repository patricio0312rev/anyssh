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

        let outcome = try await navigator.jump(toSession: MuxSessionID(rawValue: "$1"))

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

        let outcome = try await navigator.jump(toSession: MuxSessionID(rawValue: "$2"))

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

        let outcome = try await navigator.jump(toSession: MuxSessionID(rawValue: "$2"))

        #expect(outcome == .skipped(MuxSessionID(rawValue: "$2"), .unidentified))
        #expect(await adapter.switchLog.switches.isEmpty)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aRefusedSwitchOnAnAttachedTerminalSkipsTheSession() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .herdrDefault)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) {
            .attached(MuxSessionID(rawValue: "default"))
        }

        let outcome = try await navigator.jump(toSession: MuxSessionID(rawValue: "review"))

        #expect(
            outcome == .skipped(MuxSessionID(rawValue: "review"), .refused(.mux(.sessionSwitchUnsupported)))
        )
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aDetachedTerminalSkipsTheSessionWithoutTypingIntoIt() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .detached }

        let outcome = try await navigator.jump(toSession: MuxSessionID(rawValue: "$2"))

        #expect(outcome == .skipped(MuxSessionID(rawValue: "$2"), .detached))
        #expect(await adapter.switchLog.switches.isEmpty)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func anUnknownAttachmentNeverSwitchesAnotherClient() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .unknown }

        let outcome = try await navigator.jump(toSession: MuxSessionID(rawValue: "$2"))

        #expect(outcome == .skipped(MuxSessionID(rawValue: "$2"), .unreadable))
        #expect(await adapter.switchLog.switches.isEmpty)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aGroupJumpOnTheBoundSessionOnlyFocusesTheTab() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let bound = target.session
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .attached(bound) }

        #expect(try await navigator.jump(toGroup: target) == .focused)
        #expect(await adapter.focusLog.targets == [target])
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aGroupJumpOnADetachedTerminalSkipsWithoutFocusingOrTyping() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .detached }

        #expect(try await navigator.jump(toGroup: target) == .skipped(target.session, .detached))
        #expect(await adapter.focusLog.targets.isEmpty)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aGroupJumpNeverTouchesATerminalBoundElsewhere() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) {
            .attached(MuxSessionID(rawValue: "$2"))
        }

        #expect(try await navigator.jump(toGroup: target) == .skipped(target.session, .boundElsewhere))
        #expect(await adapter.focusLog.targets.isEmpty)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aGroupJumpOnAnAttachedTerminalWithNoBindingSkipsTheTab() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .attached(nil) }

        #expect(try await navigator.jump(toGroup: target) == .skipped(target.session, .unidentified))
        #expect(await adapter.focusLog.targets.isEmpty)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func anUnknownAttachmentNeverFocusesATab() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let connection = MockRemoteConnection()
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .unknown }

        #expect(try await navigator.jump(toGroup: target) == .skipped(target.session, .unreadable))
        #expect(await adapter.focusLog.targets.isEmpty)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func aVanishedTabSkipsInsteadOfFailingTheGesture() async throws {
        let adapter = SwipeRingMuxAdapter(names: ["$1"], refusesFocus: true)
        let connection = MockRemoteConnection()
        let bound = target.session
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .attached(bound) }

        #expect(
            try await navigator.jump(toGroup: target)
                == .skipped(target.session, .refused(.mux(.attachTargetVanished)))
        )
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func anUnexpectedFocusFailurePropagatesFromAGroupJump() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .absent)
        let connection = MockRemoteConnection()
        let bound = target.session
        let navigator = MuxNavigator(adapter: adapter, writer: connection) { .attached(bound) }

        await #expect(throws: ErrorState.mux(.absent)) {
            _ = try await navigator.jump(toGroup: target)
        }
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
