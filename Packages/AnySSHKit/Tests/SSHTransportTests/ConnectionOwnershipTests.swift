import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite struct ConnectionOwnershipTests {
    private static let owned = ["SSHTerminalTransport", "ControlTransport", "SSHChannel"]
    private static let owningDirectories = [
        "Sources/SSHTransport/Connection/",
        "Sources/SSHTransport/Display/",
    ]

    @Test func noModuleOutsideTheConnectionNamesATransport() throws {
        let offenders = try Self.sources().filter { url in
            let path = Self.relative(url)
            guard !Self.owningDirectories.contains(where: path.hasPrefix) else { return false }
            let text = try String(contentsOf: url, encoding: .utf8)
            return Self.owned.contains { text.contains($0) }
        }

        #expect(offenders.map(Self.relative) == [])
    }

    @Test func theConnectionIsUsableThroughItsPort() async {
        let connection: any RemoteConnection = ConnectionTestbed.connection()

        #expect(connection.connectionID.rawValue.isEmpty == false)
        #expect(await connection.displayState == .idle)
        #expect(await connection.controlState == .idle)
        #expect(await connection.openChannelCount == 0)
    }

    private static func sources() throws -> [URL] {
        let root = repositoryRoot().appending(path: "Packages/AnySSHKit/Sources")
        guard let walker = FileManager.default.enumerator(atPath: root.path()) else { return [] }
        return walker.compactMap { entry in
            guard let name = entry as? String, name.hasSuffix(".swift") else { return nil }
            return root.appending(path: name)
        }
    }

    private static func relative(_ url: URL) -> String {
        let root = repositoryRoot().appending(path: "Packages/AnySSHKit/").path()
        return url.path().replacingOccurrences(of: root, with: "")
    }

    private static func repositoryRoot() -> URL {
        var url = URL(filePath: #filePath)
        for _ in 0..<5 { url = url.deletingLastPathComponent() }
        return url
    }
}
