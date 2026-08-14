@MainActor
public final class AppCommandRegistry {
    public private(set) var commands: [AppCommand]

    private var byID: [String: AppCommand]

    public init(commands: [AppCommand]) {
        self.commands = commands
        byID = Dictionary(uniqueKeysWithValues: commands.map { ($0.id, $0) })
    }

    public func replace(with commands: [AppCommand]) {
        self.commands = commands
        byID = Dictionary(uniqueKeysWithValues: commands.map { ($0.id, $0) })
    }

    public func command(id: String) -> AppCommand? {
        byID[id]
    }

    public func command(matching event: AppShortcutEvent) -> AppCommand? {
        commands.first { $0.keyEquivalent?.matches(event) == true }
    }

    public func run(id: String) {
        guard let command = byID[id], command.isEnabled() else { return }
        command.handler()
    }
}
