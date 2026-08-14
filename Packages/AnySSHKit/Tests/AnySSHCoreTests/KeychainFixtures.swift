import Foundation
import Synchronization

@testable import AnySSHCore

enum KeychainFixture {
    static let remote = RemoteID(rawValue: "gate-host")
    static let privateKey = SecretReference(remoteID: remote, kind: .privateKey)
    static let passphrase = SecretReference(remoteID: remote, kind: .keyPassphrase)
    static let password = SecretReference(remoteID: remote, kind: .password)

    static let token = "ZmFrZXNlY3JldHRva2Vu"

    static let keyLength = 3072

    static let keyMaterial: Data = {
        let header = "-----BEGIN OPENSSH PRIVATE KEY-----\n"
        let footer = "\n-----END OPENSSH PRIVATE KEY-----\n"
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")
        var body = token
        var index = 0
        while header.utf8.count + body.utf8.count + footer.utf8.count < keyLength {
            body.append(alphabet[index % alphabet.count])
            index += 1
        }
        return Data((header + body + footer).utf8)
    }()

    static func legacyItem(_ remoteID: String) -> KeychainItem {
        KeychainItem(
            service: KeychainSchema.service,
            account: remoteID,
            version: KeychainSchema.unversioned,
            gate: .none
        )
    }

    static func payload(_ label: String) -> Data {
        Data("\(token)/\(label)".utf8)
    }
}

enum LiveKeychain {
    static let service = "dev.anyssh.livetest"

    static let isReachable: Bool = {
        guard ProcessInfo.processInfo.environment["ANYSSH_LIVE_KEYCHAIN"] == "1" else {
            return false
        }
        let backend = SecItemKeychain(dataProtection: false)
        let probe = KeychainItem(
            service: service,
            account: "probe",
            version: KeychainSchema.currentVersion,
            gate: .none
        )
        do {
            try backend.delete(probe)
            try backend.add(probe, secret: Data("probe".utf8))
            try backend.delete(probe)
            return true
        } catch {
            return false
        }
    }()
}

struct StubPresentation: BiometricPresentation {
    func apply(to query: inout [String: Any]) {
        query["fixture.presentation"] = true
    }
}

final class ScriptedGate: BiometricAuthenticator {
    private let outcome: BiometricOutcome
    private let presents: Bool
    private let asked = Mutex(0)

    init(_ outcome: BiometricOutcome, presents: Bool = true) {
        self.outcome = outcome
        self.presents = presents
    }

    var attempts: Int {
        asked.withLock { $0 }
    }

    func authenticate(reason: String) async -> BiometricResult {
        asked.withLock { $0 += 1 }
        guard outcome == .authenticated, presents else { return BiometricResult(outcome) }
        return BiometricResult(outcome, presentation: StubPresentation())
    }
}
