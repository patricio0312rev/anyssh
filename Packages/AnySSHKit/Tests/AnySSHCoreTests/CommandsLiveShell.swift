#if os(macOS)
import Foundation

enum LiveShellHost {
    static var target: String { "\(setting("ANYSSH_LIVE_USER", "dev"))@\(host)" }
    static var host: String { setting("ANYSSH_LIVE_HOST", "192.0.2.10") }

    static var isReachable: Bool {
        (try? run("true"))?.exitCode == 0
    }

    static func run(_ command: String) throws -> CommandsSubprocess.Outcome {
        try CommandsSubprocess.run(
            "/usr/bin/ssh",
            [
                "-o", "BatchMode=yes",
                "-o", "ConnectTimeout=5",
                "-o", "StrictHostKeyChecking=accept-new",
                "-i", setting("ANYSSH_LIVE_KEY", NSHomeDirectory() + "/.ssh/anyssh_dev_ed25519"),
                "-p", setting("ANYSSH_LIVE_PORT", "22"),
                target, "/bin/sh", "-s",
            ],
            stdin: Data(command.utf8)
        )
    }

    private static func setting(_ key: String, _ fallback: String) -> String {
        let value = ProcessInfo.processInfo.environment[key] ?? ""
        return value.isEmpty ? fallback : value
    }
}
#endif
