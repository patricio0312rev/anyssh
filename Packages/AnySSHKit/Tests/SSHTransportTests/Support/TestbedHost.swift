import Foundation

struct TestbedHost: Sendable {
    var host: String
    var port: Int32

    static let sshd = TestbedHost(
        host: Environment.value("ANYSSH_TESTBED_HOST", "127.0.0.1"),
        port: Int32(Environment.value("ANYSSH_TESTBED_PORT", "2222")) ?? 2222
    )

    static let development = TestbedHost(
        host: LiveHost.development.host,
        port: LiveHost.development.port
    )

    static var isReachable: Bool {
        sshd.answers
    }

    static var isDevelopmentHostReachable: Bool {
        development.answers
    }

    var answers: Bool {
        guard let descriptor = PosixSocket.connect(host: host, port: port, timeout: 2) else {
            return false
        }
        PosixSocket.close(descriptor)
        return true
    }
}

enum Environment {
    static func value(_ key: String, _ fallback: String) -> String {
        let value = ProcessInfo.processInfo.environment[key] ?? ""
        return value.isEmpty ? fallback : value
    }
}

enum AvailableSSHHost {
    static var endpoint: (host: String, port: Int)? {
        for candidate in [TestbedHost.sshd, TestbedHost.development] where candidate.answers {
            return (candidate.host, Int(candidate.port))
        }
        return nil
    }

    static var isAvailable: Bool {
        endpoint != nil
    }
}
