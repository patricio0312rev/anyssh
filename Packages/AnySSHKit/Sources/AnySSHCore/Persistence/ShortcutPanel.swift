public struct ShortcutPanel: Codable, Hashable, Sendable, Identifiable {
    public enum Scope: String, Codable, Hashable, Sendable, CaseIterable {
        case tmux
        case herdr
        case agent
        case custom
    }

    public struct Entry: Codable, Hashable, Sendable, Identifiable {
        public enum Payload: Codable, Hashable, Sendable {
            case chord(String)
            case text(String)
        }

        public let id: String
        public let label: String
        public let payload: Payload

        public init(id: String, label: String, payload: Payload) {
            self.id = id
            self.label = label
            self.payload = payload
        }
    }

    public let id: String
    public let scope: Scope
    public let name: String
    public let entries: [Entry]

    public init(id: String, scope: Scope, name: String, entries: [Entry]) {
        self.id = id
        self.scope = scope
        self.name = name
        self.entries = entries
    }

    public func entry(id: String) -> Entry? {
        entries.first { $0.id == id }
    }

    public func replacing(_ entry: Entry) -> ShortcutPanel {
        let updated =
            entries.contains { $0.id == entry.id }
            ? entries.map { $0.id == entry.id ? entry : $0 }
            : entries + [entry]
        return ShortcutPanel(id: id, scope: scope, name: name, entries: updated)
    }
}
