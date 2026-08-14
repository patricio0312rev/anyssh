#if os(macOS)
import Foundation
import Testing

@testable import AnySSHCore

@Suite(.enabled(if: RealKey.areReadable))
struct KeyMaterialRealKeyTests {
    @Test(arguments: RealKey.all)
    func aRealKeyClassifiesTheWaySSHKeygenSaysItShould(key: RealKey) throws {
        let parsed = try KeyMaterialParser.parse(KeyMaterialBuffer(try key.bytes()))
        let announced = try #require(try key.sshKeygenLine())

        #expect(parsed.format == .openSSH, "\(key.name) format")
        #expect(parsed.fingerprint == announced.fingerprint, "\(key.name) fingerprint")
        #expect(parsed.bitCount == announced.bitCount, "\(key.name) bits")
        #expect(parsed.algorithm.label == announced.algorithm, "\(key.name) algorithm")
    }

    @Test func anEncryptedKeyIsSeenAsEncryptedAndAPlainOneIsNot() throws {
        for key in RealKey.all {
            let parsed = try KeyMaterialParser.parse(KeyMaterialBuffer(try key.bytes()))
            #expect(parsed.isEncrypted == key.isEncrypted, "\(key.name) encrypted flag")
        }
    }

    @Test func theRealPublicHalfIsRefusedAsAPublicKey() throws {
        for key in RealKey.all {
            let publicHalf = try Data(contentsOf: URL(filePath: key.path + ".pub"))
            #expect(throws: KeyMaterialError.publicKeyOffered(key.algorithm)) {
                _ = try KeyMaterialParser.parse(KeyMaterialBuffer(Array(publicHalf)))
            }
        }
    }
}

struct RealKey: Sendable, CustomTestStringConvertible {
    struct Announcement: Sendable {
        let bitCount: Int
        let fingerprint: String
        let algorithm: String
    }

    let name: String
    let isEncrypted: Bool
    let algorithm: PrivateKeyAlgorithm

    var path: String {
        NSHomeDirectory() + "/.ssh/" + name
    }

    var testDescription: String {
        name
    }

    func bytes() throws -> [UInt8] {
        Array(try Data(contentsOf: URL(filePath: path)))
    }

    func sshKeygenLine() throws -> Announcement? {
        let outcome = try CommandsSubprocess.run("/usr/bin/ssh-keygen", ["-lf", path + ".pub"])
        let fields = String(decoding: outcome.stdout, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
        guard outcome.exitCode == 0, fields.count >= 3, let bits = Int(fields[0]) else { return nil }
        let algorithm = String(fields[fields.count - 1].trimmingCharacters(in: ["(", ")"]))
        return Announcement(bitCount: bits, fingerprint: String(fields[1]), algorithm: algorithm)
    }

    static let all: [RealKey] = [
        RealKey(name: "anyssh_dev_ed25519", isEncrypted: false, algorithm: .ed25519),
        RealKey(name: "anyssh_dev_rsa", isEncrypted: false, algorithm: .rsa),
        RealKey(name: "anyssh_testbed_locked_ed25519", isEncrypted: true, algorithm: .ed25519),
    ]

    static let areReadable: Bool = all.allSatisfy {
        FileManager.default.isReadableFile(atPath: $0.path)
            && FileManager.default.isReadableFile(atPath: $0.path + ".pub")
    }
}
#endif
