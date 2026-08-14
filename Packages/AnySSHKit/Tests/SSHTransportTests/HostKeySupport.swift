import AnySSHCore
import Fixtures
import Foundation

@testable import SSHTransport

enum HostKeyFixture {
    static let ed25519 = key("hostkeys/ed25519.pub")
    static let rsa = key("hostkeys/rsa.pub")
    static let changed = key("hostkeys/ed25519-changed.pub")

    static let recordedFingerprints: [String] = {
        let text = (try? String(contentsOf: FixtureBundle.url("hostkeys/fingerprints.txt"), encoding: .utf8))
        return (text ?? "").split(separator: "\n").map(String.init)
    }()

    static func recordedFingerprint(comment: String) -> String? {
        recordedFingerprints
            .first { $0.contains(" \(comment) ") }?
            .split(separator: " ")
            .first { $0.hasPrefix("SHA256:") }
            .map(String.init)
    }

    private static func key(_ path: String) -> HostKey {
        guard let text = try? String(contentsOf: FixtureBundle.url(path), encoding: .utf8),
            let encoded = text.split(separator: " ").dropFirst().first,
            let raw = Data(base64Encoded: String(encoded))
        else { return HostKey(algorithm: .unknown, raw: []) }
        return HostKey(blob: Array(raw))
    }
}

struct HostKeyTempDirectory {
    let url: URL

    init() {
        url = URL.temporaryDirectory.appending(path: "anyssh-hostkeys-\(UUID().uuidString)")
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }

    var knownHostsText: String {
        (try? String(contentsOf: url.appending(path: KnownHostsFile.name), encoding: .utf8)) ?? ""
    }
}

actor MemoryHostKeyStore: HostKeyStore {
    private var keys = [String: HostKey]()

    func knownKey(host: String, port: Int) async throws -> HostKey? {
        keys[Self.identifier(host, port)]
    }

    func remember(_ key: HostKey, host: String, port: Int) async throws {
        keys[Self.identifier(host, port)] = key
    }

    func forget(host: String, port: Int) async throws {
        keys[Self.identifier(host, port)] = nil
    }

    private static func identifier(_ host: String, _ port: Int) -> String {
        "\(host):\(port)"
    }
}

enum TestTrust {
    static func acceptingFirstUse() -> HostKeyTrust {
        HostKeyTrust(
            store: MemoryHostKeyStore(),
            question: HostKeyQuestion { _, _ in .accept(remember: true) }
        )
    }
}

final class ScriptedTrustAnswer: @unchecked Sendable {
    private let lock = NSLock()
    private let verdict: HostKeyVerdict
    private var questions = [KnownHostStatus]()

    init(_ verdict: HostKeyVerdict) {
        self.verdict = verdict
    }

    var asked: Int {
        lock.withLock { questions.count }
    }

    var lastStatus: KnownHostStatus? {
        lock.withLock { questions.last }
    }

    var question: HostKeyQuestion {
        HostKeyQuestion { [self] _, status in
            lock.withLock { questions.append(status) }
            return verdict
        }
    }
}
