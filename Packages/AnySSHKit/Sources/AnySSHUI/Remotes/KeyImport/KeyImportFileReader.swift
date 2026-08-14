import AnySSHCore
import Foundation

public enum KeyImportFileReader {
    public static func read(_ url: URL) throws -> KeyMaterialBuffer {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= KeyMaterialError.sizeLimit else { throw KeyMaterialError.tooLarge }

        var contents = try Data(contentsOf: url, options: [.uncached])
        defer { contents.resetBytes(in: 0..<contents.count) }
        return KeyMaterialBuffer(contents)
    }
}
