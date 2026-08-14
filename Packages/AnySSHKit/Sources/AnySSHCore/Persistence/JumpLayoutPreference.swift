import Foundation

public enum JumpLayout: String, Codable, Hashable, Sendable, CaseIterable {
    case list
    case accordion
    case grid
}

public struct JumpLayoutPreference: Codable, Hashable, Sendable {
    public static let schemaVersion = 1
    public static let fileName = "jump-layout.json"
    public static let defaults = JumpLayout.list

    private struct Envelope: Codable {
        let schemaVersion: Int
        let layout: JumpLayout
    }

    public static func load(from directory: URL?) -> JumpLayout {
        guard let directory,
            let data = try? Data(contentsOf: fileURL(in: directory)),
            let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
            envelope.schemaVersion == schemaVersion
        else { return defaults }
        return envelope.layout
    }

    public static func save(_ layout: JumpLayout, to directory: URL?) {
        guard let directory else { return }
        let envelope = Envelope(schemaVersion: schemaVersion, layout: layout)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? encoder.encode(envelope).write(to: fileURL(in: directory), options: .atomic)
    }

    public static func fileURL(in directory: URL) -> URL {
        directory.appending(path: fileName)
    }
}
