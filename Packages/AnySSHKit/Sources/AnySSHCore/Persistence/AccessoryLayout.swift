import Foundation

public struct AccessoryLayout: Codable, Hashable, Sendable {
    public static let schemaVersion = 1
    public static let fileName = "accessory-layout.json"

    public struct Binding: Codable, Hashable, Sendable {
        public enum Kind: String, Codable, Hashable, Sendable {
            case none
            case key
            case modifier
            case chord
            case prefix
        }

        public let kind: Kind
        public let value: String?

        public init(kind: Kind, value: String? = nil) {
            self.kind = kind
            self.value = value
        }

        public static let none = Binding(kind: .none)

        public static func key(_ value: String) -> Binding {
            Binding(kind: .key, value: value)
        }

        public static func modifier(_ value: String) -> Binding {
            Binding(kind: .modifier, value: value)
        }

        public static func chord(_ value: String) -> Binding {
            Binding(kind: .chord, value: value)
        }

        public static func prefix() -> Binding {
            Binding(kind: .prefix)
        }
    }

    public struct Key: Codable, Hashable, Sendable, Identifiable {
        public let id: String
        public let label: String
        public let repeats: Bool
        public let tap: Binding
        public let doubleTap: Binding
        public let longPress: Binding

        public init(
            id: String,
            label: String,
            repeats: Bool = false,
            tap: Binding,
            doubleTap: Binding = .none,
            longPress: Binding = .none
        ) {
            self.id = id
            self.label = label
            self.repeats = repeats
            self.tap = tap
            self.doubleTap = doubleTap
            self.longPress = longPress
        }
    }

    private struct Envelope: Codable {
        let schemaVersion: Int
        let keys: [Key]
    }

    public let keys: [Key]

    public init(keys: [Key]) {
        self.keys = keys
    }

    public static let defaults = AccessoryLayout(keys: [
        key("escape", "Esc", "escape"),
        key("tab", "Tab", "tab"),
        key("control", "Ctrl", modifier: "control"),
        key("alt", "Alt", modifier: "alt"),
        key("up", "↑", "up", repeats: true),
        key("down", "↓", "down", repeats: true),
        key("left", "←", "left", repeats: true),
        key("right", "→", "right", repeats: true),
        key("pipe", "|", "|"),
        key("tilde", "~", "~"),
        prefixKey,
        key("slash", "/", "/"),
        key("minus", "-", "-"),
    ])

    public static let prefixKey = Key(
        id: "terminal.accessory.key.prefix",
        label: "PRE",
        tap: .prefix()
    )

    public static func load(from directory: URL) -> AccessoryLayout {
        let url = fileURL(in: directory)
        guard let data = try? Data(contentsOf: url),
            let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
            envelope.schemaVersion == schemaVersion,
            !envelope.keys.isEmpty
        else { return defaults }
        return AccessoryLayout(keys: envelope.keys)
    }

    public func save(to directory: URL) throws {
        let envelope = Envelope(schemaVersion: Self.schemaVersion, keys: keys)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(envelope)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: Self.fileURL(in: directory), options: .atomic)
    }

    public static func fileURL(in directory: URL) -> URL {
        directory.appending(path: fileName)
    }

    public static let defaultLocation = URL.applicationSupportDirectory
        .appending(path: "AnySSH")
        .appending(path: "remotes.json")

    public static func directory(for remoteStoreLocation: URL) -> URL {
        remoteStoreLocation.deletingLastPathComponent()
    }

    public static func load(for remoteStoreLocation: URL) -> AccessoryLayout {
        load(from: directory(for: remoteStoreLocation))
    }

    public func save(for remoteStoreLocation: URL) throws {
        try save(to: Self.directory(for: remoteStoreLocation))
    }

    public func moved(id: String, before targetID: String?) -> AccessoryLayout {
        guard let source = keys.firstIndex(where: { $0.id == id }) else { return self }
        var updated = keys
        let item = updated.remove(at: source)
        let target = targetID.flatMap { target in updated.firstIndex { $0.id == target } }
        updated.insert(item, at: target ?? updated.count)
        return AccessoryLayout(keys: updated)
    }

    public func adding(_ key: Key) -> AccessoryLayout {
        AccessoryLayout(keys: keys + [key])
    }

    public func removing(id: String) -> AccessoryLayout {
        AccessoryLayout(keys: keys.filter { $0.id != id })
    }

    public func ensuringPrefixKey() -> AccessoryLayout {
        guard !keys.contains(where: { $0.tap.kind == .prefix }) else { return self }
        if let backtick = keys.firstIndex(where: { $0.id == "terminal.accessory.key.backtick" }) {
            var updated = keys
            updated[backtick] = Self.prefixKey
            return AccessoryLayout(keys: updated)
        }
        return adding(Self.prefixKey)
    }

    private static func key(
        _ id: String,
        _ label: String,
        _ value: String? = nil,
        repeats: Bool = false,
        modifier: String? = nil
    ) -> Key {
        let tap = modifier.map(Binding.modifier) ?? .key(value ?? id)
        let longPress = repeats ? tap : .none
        return Key(
            id: "terminal.accessory.key.\(id)",
            label: label,
            repeats: repeats,
            tap: tap,
            longPress: longPress
        )
    }
}
