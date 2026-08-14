import Foundation
import Testing

@Suite struct SessionInterfaceTests {
    @Test func noSourceFileConstrainsTheNetworkInterface() throws {
        let forbidden = ["required" + "InterfaceType", "prohibited" + "InterfaceTypes", "IP_" + "BOUND_IF"]
        let root = repositoryRoot()
        let trees = ["AnySSH", "AnySSHUITests", "Packages/AnySSHKit/Sources", "Packages/AnySSHKit/Tests"]

        var offenders = [String]()
        for tree in trees {
            for file in swiftFiles(under: root.appending(path: tree)) {
                let contents = try String(contentsOf: file, encoding: .utf8)
                for symbol in forbidden where contents.contains(symbol) {
                    offenders.append("\(file.lastPathComponent): \(symbol)")
                }
            }
        }

        #expect(offenders.isEmpty, "interface constraints found: \(offenders)")
    }

    private func repositoryRoot() -> URL {
        var url = URL(filePath: #filePath)
        for _ in 0..<5 { url = url.deletingLastPathComponent() }
        return url
    }

    private func swiftFiles(under directory: URL) -> [URL] {
        guard
            let walker = FileManager.default.enumerator(
                at: directory,
                includingPropertiesForKeys: nil
            )
        else { return [] }
        return walker.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
    }
}
