import Foundation

@testable import AnySSHCore

struct TemporaryDirectory {
    let url: URL

    init() {
        url = URL.temporaryDirectory.appending(path: "RemoteStoreTests-\(UUID().uuidString)")
    }

    var storeFile: URL {
        url.appending(path: FileRemoteStore.fileName)
    }

    func contents() throws -> String {
        String(decoding: try Data(contentsOf: storeFile), as: UTF8.self)
    }

    func write(_ text: String) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try Data(text.utf8).write(to: storeFile)
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}

enum RemoteStoreFixture {
    static let awkward = Remote(
        id: RemoteID(rawValue: "awkward"),
        name: "He said \"hi\"\n🚀 box",
        host: "quote\"host\n🌍.example.net",
        port: 2022,
        username: "us\"er\n🧑",
        authMethod: .keyboardInteractive,
        startPath: "~/dir with \"quotes\"\nand a 🐚",
        startupCommand: "echo \"hello\"\nprintf '🎉\\n'",
        tag: "tag \"one\"\n🏷️"
    )

    static func numbered(_ index: Int) -> Remote {
        Remote(
            id: RemoteID(rawValue: "host-\(index)"),
            name: "Host \(index)",
            host: "host\(index).example.net",
            port: 2200 + index,
            username: "user\(index)",
            authMethod: .publicKey,
            startPath: "~/work/\(index)",
            startupCommand: "tmux attach -t \(index)",
            tag: "tag-\(index)",
            orderIndex: index
        )
    }

    static func authenticated(by method: AuthMethod) -> Remote {
        let index = AuthMethod.allCases.firstIndex(of: method) ?? 0
        return Remote(
            id: RemoteID(rawValue: "auth-\(index)"),
            name: "Auth \(index)",
            host: "auth\(index).example.net",
            username: "operator",
            authMethod: method
        )
    }
}
