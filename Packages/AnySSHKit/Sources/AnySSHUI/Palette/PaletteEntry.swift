public struct PaletteEntry: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let keyLabel: String?
    public let isEnabled: Bool
    public let disabledReason: String?

    public init(
        id: String,
        title: String,
        keyLabel: String?,
        isEnabled: Bool,
        disabledReason: String?
    ) {
        self.id = id
        self.title = title
        self.keyLabel = keyLabel
        self.isEnabled = isEnabled
        self.disabledReason = disabledReason
    }
}

public struct CommandPaletteModel: Equatable, Sendable {
    public private(set) var query: String
    public private(set) var matches: [PaletteEntry]
    public private(set) var selection: Int

    private let entries: [PaletteEntry]

    public init(entries: [PaletteEntry], query: String = "") {
        self.entries = entries
        self.query = query
        matches = []
        selection = 0
        recompute()
    }

    public var selected: PaletteEntry? {
        matches.indices.contains(selection) ? matches[selection] : nil
    }

    public mutating func setQuery(_ text: String) {
        guard text != query else { return }
        query = text
        recompute()
    }

    public mutating func moveUp() {
        move(by: -1)
    }

    public mutating func moveDown() {
        move(by: 1)
    }

    private mutating func move(by delta: Int) {
        guard !matches.isEmpty else {
            selection = 0
            return
        }
        for offset in 1...matches.count {
            let candidate = (selection + delta * offset + matches.count) % matches.count
            if matches[candidate].isEnabled {
                selection = candidate
                return
            }
        }
        selection = 0
    }

    private mutating func recompute() {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        matches =
            needle.isEmpty
            ? entries
            : entries.filter {
                $0.title.lowercased().contains(needle) || $0.id.lowercased().contains(needle)
            }
        selection = matches.firstIndex(where: \.isEnabled) ?? 0
    }
}
