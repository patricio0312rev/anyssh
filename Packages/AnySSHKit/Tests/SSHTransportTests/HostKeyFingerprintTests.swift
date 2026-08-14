import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite struct HostKeyFingerprintTests {
    @Test func openSSHFormReproducesSSHKeygenForTheEd25519Fixture() throws {
        let recorded = try #require(HostKeyFixture.recordedFingerprint(comment: "anyssh-hostkey-fixture"))

        #expect(HostKeyFixture.ed25519.fingerprint.openSSH == recorded)
        #expect(recorded == "SHA256:JBVSLVw5Dir1CNOuopXRGhbAlBFz3i51tFzLzY/Vidk")
    }

    @Test func openSSHFormReproducesSSHKeygenForTheRSAFixture() throws {
        let recorded = try #require(
            HostKeyFixture.recordedFingerprint(comment: "anyssh-hostkey-fixture-rsa"))

        #expect(HostKeyFixture.rsa.fingerprint.openSSH == recorded)
        #expect(HostKeyFixture.rsa.algorithm == .rsa)
    }

    @Test func openSSHFormReproducesSSHKeygenForTheChangedFixture() throws {
        let recorded = try #require(
            HostKeyFixture.recordedFingerprint(comment: "anyssh-hostkey-fixture-changed"))

        #expect(HostKeyFixture.changed.fingerprint.openSSH == recorded)
    }

    @Test func theOpenSSHFormCarriesNoPadding() {
        let fingerprint = HostKeyFixture.ed25519.fingerprint

        #expect(fingerprint.openSSH.hasPrefix("SHA256:"))
        #expect(!fingerprint.openSSH.hasSuffix("="))
        #expect(fingerprint.openSSH.count == 50)
    }

    @Test func theHexFormIsSixtyFourCharactersOfTheSameDigest() {
        let fingerprint = HostKeyFixture.ed25519.fingerprint

        #expect(fingerprint.digest.count == 32)
        #expect(fingerprint.hex.count == 64)
        #expect(fingerprint.hex == "2415522d5c390e2af508d3aea295d11a16c0941173de2e75b45ccbcd8fd589d9")
        #expect(fingerprint.hex.allSatisfy { $0.isHexDigit && !$0.isUppercase })
    }

    @Test func comparisonRunsOverBytesRatherThanText() {
        let stored = HostKeyFixture.ed25519
        let offered = HostKeyFixture.changed

        #expect(!stored.matches(offered))
        #expect(stored.fingerprint.openSSH != offered.fingerprint.openSSH)
        #expect(stored.matches(HostKey(algorithm: .ed25519, raw: stored.raw)))
        #expect(!stored.matches(HostKey(algorithm: .rsa, raw: stored.raw)))
    }

    @Test func oneFlippedByteIsADifferentKey() throws {
        var raw = HostKeyFixture.ed25519.raw
        let last = try #require(raw.indices.last)
        raw[last] ^= 0x01

        let tampered = HostKey(algorithm: .ed25519, raw: raw)
        #expect(!HostKeyFixture.ed25519.matches(tampered))
        #expect(HostKeyFixture.ed25519.fingerprint.digest != tampered.fingerprint.digest)
    }

    @Test func theBlobNamesItsOwnAlgorithm() {
        #expect(HostKeyBlob.typeName(of: HostKeyFixture.ed25519.raw) == "ssh-ed25519")
        #expect(HostKeyBlob.typeName(of: HostKeyFixture.rsa.raw) == "ssh-rsa")
        #expect(HostKeyFixture.ed25519.algorithm == .ed25519)
        #expect(HostKeyBlob.typeName(of: []) == nil)
        #expect(HostKeyBlob.typeName(of: [0, 0, 0, 200, 1, 2]) == nil)
        #expect(HostKeyBlob.algorithm(named: "ecdsa-sha2-nistp521") == .ecdsa)
        #expect(HostKeyBlob.algorithm(named: "ssh-dss") == .unknown)
    }
}
