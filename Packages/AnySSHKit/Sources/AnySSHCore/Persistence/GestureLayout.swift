import Foundation

public struct GestureLayout: Codable, Hashable, Sendable {
    public static let schemaVersion = 1
    public static let fileName = "gesture-layout.json"

    public struct Binding: Codable, Hashable, Sendable {
        public enum Kind: String, Codable, Hashable, Sendable {
            case chord
            case multiplexer
            case appCommand
        }

        public let kind: Kind
        public let value: String

        public init(kind: Kind, value: String) {
            self.kind = kind
            self.value = value
        }
    }

    private struct Envelope: Codable {
        let schemaVersion: Int
        let bindings: [String: Binding]
    }

    public let bindings: [String: Binding]

    public init(bindings: [String: Binding]) {
        self.bindings = bindings
    }

    public static let defaults = GestureLayout(bindings: [
        "doubleTap": Binding(kind: .appCommand, value: "paste"),
        "swipeLeft": Binding(kind: .appCommand, value: "session.previous"),
        "swipeRight": Binding(kind: .appCommand, value: "session.next"),
        "swipeUp": Binding(kind: .appCommand, value: "view.terminal"),
        "swipeDown": Binding(kind: .appCommand, value: "view.changes"),
        "twoFingerSwipeLeft": Binding(kind: .multiplexer, value: "previous_pane"),
        "twoFingerSwipeRight": Binding(kind: .multiplexer, value: "next_pane"),
        "twoFingerSwipeUp": Binding(kind: .appCommand, value: "open_changes"),
        "twoFingerSwipeDown": Binding(kind: .appCommand, value: "close_changes"),
        "pinch": Binding(kind: .appCommand, value: "change_font_size"),
    ])

    public static func load(from directory: URL) -> Self {
        guard let data = try? Data(contentsOf: fileURL(in: directory)),
            let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
            envelope.schemaVersion == schemaVersion
        else { return defaults }
        return GestureLayout(bindings: envelope.bindings)
    }

    public func save(to directory: URL) throws {
        let envelope = Envelope(schemaVersion: Self.schemaVersion, bindings: bindings)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try encoder.encode(envelope).write(to: Self.fileURL(in: directory), options: .atomic)
    }

    public static func fileURL(in directory: URL) -> URL { directory.appending(path: fileName) }

    public func reset() -> Self { Self.defaults }

    public func binding(for slot: String) -> Binding? { bindings[slot] }

    public func setting(_ binding: Binding?, for slot: String) -> Self {
        var updated = bindings
        updated[slot] = binding
        return Self(bindings: updated)
    }
}
