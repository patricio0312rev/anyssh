import Foundation

public struct ShortcutPanelLayout: Codable, Hashable, Sendable {
    public static let schemaVersion = 1
    public static let fileName = "shortcut-panels.json"

    private struct Envelope: Codable {
        let schemaVersion: Int
        let panels: [ShortcutPanel]
    }

    public let panels: [ShortcutPanel]

    public init(panels: [ShortcutPanel]) {
        self.panels = panels
    }

    public var scopes: [ShortcutPanel.Scope] {
        panels.map(\.scope)
    }

    public func panel(scope: ShortcutPanel.Scope) -> ShortcutPanel? {
        panels.first { $0.scope == scope }
    }

    public func contains(scope: ShortcutPanel.Scope) -> Bool {
        panel(scope: scope) != nil
    }

    public func replacing(_ panel: ShortcutPanel) -> ShortcutPanelLayout {
        let updated =
            panels.contains { $0.scope == panel.scope }
            ? panels.map { $0.scope == panel.scope ? panel : $0 }
            : panels + [panel]
        return ShortcutPanelLayout(panels: updated)
    }

    public func removing(scope: ShortcutPanel.Scope) -> ShortcutPanelLayout {
        ShortcutPanelLayout(panels: panels.filter { $0.scope != scope })
    }

    public static func load(from directory: URL) -> ShortcutPanelLayout {
        let url = fileURL(in: directory)
        guard let data = try? Data(contentsOf: url),
            let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
            envelope.schemaVersion == schemaVersion,
            !envelope.panels.isEmpty
        else { return ShortcutPanelDefaults.standard }
        return ShortcutPanelLayout(panels: envelope.panels)
    }

    public func save(to directory: URL) throws {
        let envelope = Envelope(schemaVersion: Self.schemaVersion, panels: panels)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(envelope)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: Self.fileURL(in: directory), options: .atomic)
    }

    public static func fileURL(in directory: URL) -> URL {
        directory.appending(path: fileName)
    }

    public static func directory(for remoteStoreLocation: URL) -> URL {
        remoteStoreLocation.deletingLastPathComponent()
    }

    public static func load(for remoteStoreLocation: URL) -> ShortcutPanelLayout {
        load(from: directory(for: remoteStoreLocation))
    }

    public func save(for remoteStoreLocation: URL) throws {
        try save(to: Self.directory(for: remoteStoreLocation))
    }
}
