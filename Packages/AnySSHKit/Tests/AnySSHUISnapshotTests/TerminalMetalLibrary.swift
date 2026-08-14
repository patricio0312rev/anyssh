import Foundation

enum TerminalMetalLibrary {
    static func lift() {
        let files = FileManager.default
        guard let root = Bundle(for: TerminalMetalLibraryAnchor.self).resourceURL else { return }
        let source = root.appending(path: "SwiftTerm_SwiftTerm.bundle/default.metallib")
        let destination = root.appending(path: "default.metallib")
        guard files.fileExists(atPath: source.path), !files.fileExists(atPath: destination.path) else {
            return
        }
        try? files.copyItem(at: source, to: destination)
    }
}

final class TerminalMetalLibraryAnchor {}
