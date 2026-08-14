import Foundation

struct LiveHost: Sendable {
    var host: String
    var port: Int32
    var username: String
    var privateKeyPath: String

    var publicKeyPath: String { privateKeyPath + ".pub" }

    static let development = LiveHost(
        host: setting("ANYSSH_LIVE_HOST", "192.0.2.10"),
        port: Int32(setting("ANYSSH_LIVE_PORT", "22")) ?? 22,
        username: setting("ANYSSH_LIVE_USER", "dev"),
        privateKeyPath: setting(
            "ANYSSH_LIVE_KEY",
            NSHomeDirectory() + "/.ssh/anyssh_dev_ed25519"
        )
    )

    static var isDevelopmentHostReachable: Bool {
        guard FileManager.default.isReadableFile(atPath: development.privateKeyPath) else {
            return false
        }
        guard
            let descriptor = PosixSocket.connect(
                host: development.host,
                port: development.port,
                timeout: 2
            )
        else { return false }
        PosixSocket.close(descriptor)
        return true
    }

    private static func setting(_ key: String, _ fallback: String) -> String {
        let value = ProcessInfo.processInfo.environment[key] ?? ""
        return value.isEmpty ? fallback : value
    }
}
