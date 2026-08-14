import Fixtures
import Foundation

struct AuthTestbed: Decodable, Sendable {
    struct Round: Decodable, Hashable, Sendable {
        let text: String
        let isEchoed: Bool
    }

    let host: String
    let port: Int
    let hostKeyAlgorithm: String
    let hostKeyBase64: String
    let hostKeyFingerprint: String
    let pubkeyAcceptedAlgorithms: [String]
    let keyboardInteractiveRounds: [Round]
    let accounts: [String: String]
}

struct TestbedCredentials: Decodable, Sendable {
    let password: String
    let wrongPassword: String
    let lockedKeyPassphrase: String
    let wrongPassphrase: String
}

enum AuthEnvironment {
    static let testbed: AuthTestbed? = decode(FixtureBundle.url("auth/testbed.json"))
    static let credentials: TestbedCredentials? = decode(
        repositoryRoot().appending(path: ".build/testbed/runtime/credentials.json")
    )

    static let ed25519 = key("anyssh_testbed_ed25519")
    static let rsa = key("anyssh_testbed_rsa")
    static let locked = key("anyssh_testbed_locked_ed25519")
    static let unauthorised = key("anyssh_dev_ed25519")

    static var isAvailable: Bool {
        testbed != nil && credentials != nil && TestbedHost.isReachable
    }

    static func key(_ name: String) -> String {
        NSHomeDirectory() + "/.ssh/" + name
    }

    private static func decode<T: Decodable>(_ url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func repositoryRoot() -> URL {
        var url = URL(filePath: #filePath)
        for _ in 0..<5 { url = url.deletingLastPathComponent() }
        return url
    }
}
