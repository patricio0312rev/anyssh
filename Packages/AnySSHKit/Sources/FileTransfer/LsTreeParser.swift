import AnySSHCore
import Foundation

public struct LsTreeParser: Sendable {
    public init() {}

    public func parse(_ bytes: Data) throws -> FileTree {
        var entries: [FileTreeEntry] = []
        var offset = 0
        while offset < bytes.count {
            guard let separator = bytes[offset...].firstIndex(of: 0x20) else { throw Error.invalidRecord }
            guard let tab = bytes[separator...].firstIndex(of: 0x09) else { throw Error.invalidRecord }
            guard let end = bytes[tab...].firstIndex(of: 0) else { throw Error.invalidRecord }
            let mode = String(decoding: bytes[offset..<separator], as: UTF8.self)
            let objectID = String(decoding: bytes[(separator + 1)..<tab], as: UTF8.self)
            let path = String(decoding: bytes[(tab + 1)..<end], as: UTF8.self)
            entries.append(FileTreeEntry(mode: mode, kind: Self.kind(mode), objectID: objectID, path: path))
            offset = end + 1
        }
        return FileTree(entries: entries)
    }

    public enum Error: Swift.Error, Sendable, Equatable {
        case invalidRecord
    }

    private static func kind(_ mode: String) -> FileTreeEntryKind {
        switch mode {
        case "040000": return .directory
        case "160000": return .submodule
        case "120000": return .symlink
        case "100644", "100755": return .file
        default: return .other
        }
    }
}
