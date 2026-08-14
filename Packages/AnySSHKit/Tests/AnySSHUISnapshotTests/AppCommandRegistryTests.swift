import AnySSHCore
import AnySSHMocks
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct AppCommandRegistryTests {
    @Test func commandIdentifiersAreUnique() {
        let commands = makeCommands()
        let ids = commands.map(\.id)
        #expect(Set(ids).count == ids.count, "every command identifier must be unique")
    }

    @Test func commandIdentifiersMatchTheEstablishedShape() throws {
        let shape = try Regex("^[a-z]+\\.[a-z][a-zA-Z]+$")
        for command in makeCommands() {
            #expect(
                command.id.wholeMatch(of: shape) != nil,
                "\(command.id) must match the group.name shape"
            )
        }
    }

    @Test func noTwoCommandsDeclareTheSameKeyEquivalent() {
        let equivalents = makeCommands().compactMap(\.keyEquivalent)
        #expect(
            Set(equivalents).count == equivalents.count,
            "no two commands may bind the same hardware chord"
        )
    }

    @Test func aKeyEquivalentResolvesToExactlyOneCommand() {
        let registry = AppCommandRegistry(commands: makeCommands())
        #expect(
            registry.command(matching: AppShortcutEvent(key: .two, command: true))?.id
                == "session.activateTwo"
        )
        #expect(
            registry.command(matching: AppShortcutEvent(key: .five, command: true))?.id
                == "session.activateFive"
        )
    }

    @Test func aDisabledCommandDoesNotRun() {
        var ran = false
        let registry = AppCommandRegistry(commands: [
            AppCommand(
                id: "app.spy",
                title: "Spy",
                keyEquivalent: nil,
                isEnabled: { false },
                disabledReason: { "Off" },
                handler: { ran = true }
            )
        ])
        registry.run(id: "app.spy")
        #expect(!ran, "a disabled command must be inert even when invoked by shortcut")
    }

    @Test func anEnabledCommandRuns() {
        var ran = false
        let registry = AppCommandRegistry(commands: [
            AppCommand(
                id: "app.spy",
                title: "Spy",
                keyEquivalent: nil,
                isEnabled: { true },
                handler: { ran = true }
            )
        ])
        registry.run(id: "app.spy")
        #expect(ran)
    }

    @Test func sessionCountShapesTheActivatePredicates() {
        let byID = Dictionary(uniqueKeysWithValues: makeCommands().map { ($0.id, $0) })
        #expect(byID["session.activateFour"]?.isEnabled() == true)
        #expect(byID["session.activateFive"]?.isEnabled() == false)
        #expect(byID["session.activateFive"]?.disabledReason() == "4 sessions open")
    }

    @Test func theBrowserCommandWaitsForAResolvedWorkspace() {
        let byID = Dictionary(uniqueKeysWithValues: makeCommands().map { ($0.id, $0) })
        #expect(byID["app.openChanges"]?.isEnabled() == true)
        #expect(byID["app.openJumpTo"]?.isEnabled() == false)
        #expect(byID["app.openJumpTo"]?.disabledReason() == "No multiplexer on this host")
    }

    private func makeCommands() -> [AppCommand] {
        AppCommandBinding.workspaceCommands(
            model: SessionWorkspaceFixture.model(),
            onNewConnection: {},
            onOpenSwitcher: {},
            onOpenPalette: {},
            onOpenChanges: {}
        )
    }
}
