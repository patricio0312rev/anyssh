import Foundation
import Testing

@testable import AnySSHCore

@Suite struct KeyMaterialTests {
    @Test(arguments: KeyFixtures.all)
    func aFixtureClassifiesTheWaySSHKeygenDoes(fixture: KeyFixture) throws {
        let parsed = try KeyMaterialParser.parse(fixture.buffer)

        #expect(parsed.format == fixture.format, "\(fixture.name) format")
        #expect(parsed.algorithm == fixture.algorithm, "\(fixture.name) algorithm")
        #expect(parsed.isEncrypted == fixture.isEncrypted, "\(fixture.name) encrypted flag")
        #expect(parsed.bitCount == fixture.bitCount, "\(fixture.name) bits")
        #expect(parsed.fingerprint == fixture.fingerprint, "\(fixture.name) fingerprint")
        #expect(parsed == fixture.expected)
    }

    @Test func everyOpenSSHKeyFingerprintsWhetherOrNotItIsLocked() throws {
        for fixture in KeyFixtures.all where fixture.format == .openSSH {
            let parsed = try KeyMaterialParser.parse(fixture.buffer)
            #expect(parsed.fingerprint != nil, "\(fixture.name) lost its fingerprint")
        }
    }

    @Test func anEncryptedPEMKeyOffersNoFingerprint() throws {
        for fixture in [KeyFixtures.rsaPEMEncrypted, KeyFixtures.rsaPKCS8Encrypted] {
            let parsed = try KeyMaterialParser.parse(fixture.buffer)
            #expect(parsed.isEncrypted)
            #expect(parsed.fingerprint == nil, "\(fixture.name) invented a fingerprint")
        }
    }

    @Test func oneKeyInTwoContainersHasOneFingerprint() throws {
        let pem = try KeyMaterialParser.parse(KeyFixtures.rsaPEM.buffer)
        let pkcs8 = try KeyMaterialParser.parse(KeyFixtures.rsaPKCS8.buffer)

        #expect(pem.fingerprint == pkcs8.fingerprint)
        #expect(pem.format != pkcs8.format)
    }

    @Test func aPublicKeyIsRefusedAndNamedAsOne() throws {
        let error = try #require(refusal(of: KeyFixtures.publicKey))

        #expect(error == .publicKeyOffered(.ed25519))
        #expect(error.stateID == "secrets.publicKeyOffered")
        #expect(error.copy.body.contains("ED25519 public half"))
        #expect(error.copy.body.contains(".pub"))
    }

    @Test func aKeyThatStopsBeforeItsEndLineIsRefusedAsIncomplete() throws {
        #expect(refusal(of: KeyFixtures.truncatedWithoutEndLine) == .truncated(.openSSH))
        #expect(refusal(of: KeyFixtures.truncatedBody) == .truncated(.openSSH))
    }

    @Test func aBodyThatDoesNotDecodeIsRefusedAsUnreadable() throws {
        #expect(refusal(of: KeyFixtures.unreadableBody) == .unreadable(.openSSH))
    }

    @Test func textThatIsNotAKeyNamesTheFormatsExpected() throws {
        let error = try #require(refusal(of: "the quick brown fox\njumped\n"))

        #expect(error == .noEnvelope)
        #expect(error.copy.body.contains("-----BEGIN OPENSSH PRIVATE KEY-----"))
        #expect(error.copy.body.contains("-----BEGIN RSA PRIVATE KEY-----"))
    }

    @Test func anEnvelopeFromAnotherToolIsToldApartFromNoEnvelopeAtAll() throws {
        let certificate = """
            -----BEGIN CERTIFICATE-----
            MIIBkTCB+w==
            -----END CERTIFICATE-----
            """

        #expect(refusal(of: certificate) == .unrecognisedEnvelope)
        #expect(refusal(of: "   \n\t\n") == .nothingToImport)
        #expect(refusal(of: "") == .nothingToImport)
    }

    @Test func armourSurvivesCarriageReturnsAndSurroundingText() throws {
        let windows = KeyFixtures.ed25519Plain.text.replacingOccurrences(of: "\n", with: "\r\n")
        let padded = "pasted from Notes:\n\n" + windows + "\n\ntrailing chatter\n"

        #expect(
            try KeyMaterialParser.parse(KeyMaterialBuffer(text: padded)).fingerprint
                == KeyFixtures.ed25519Plain.fingerprint)
    }

    @Test func hostileInputIsRefusedRatherThanTrusted() {
        var generator = SystemRandomNumberGenerator()
        let bytes = Array(KeyFixtures.ed25519Plain.text.utf8)

        for length in stride(from: 0, to: bytes.count, by: 7) {
            #expect(throws: (any Error).self) {
                _ = try KeyMaterialParser.describe(Array(bytes[0..<length]))
            }
        }
        for _ in 0..<64 {
            let noise = (0..<256).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
            #expect(throws: (any Error).self) { _ = try KeyMaterialParser.describe(noise) }
        }
    }

    @Test func everyRefusalFollowsTheToneTheRegistryEnforces() {
        let apologies = ["sorry", "oops", "whoops", "unfortunately"]
        let refusals: [KeyMaterialError] =
            [
                .nothingToImport, .noEnvelope, .unrecognisedEnvelope, .truncated(.openSSH),
                .unreadable(.rsaPKCS1),
            ] + PrivateKeyAlgorithm.allCases.map(KeyMaterialError.publicKeyOffered)

        for refusal in refusals {
            let copy = refusal.copy
            #expect(!copy.title.hasSuffix("."), "title ends in a period on \(refusal.stateID)")
            #expect(copy.body.hasSuffix("."), "body does not end in a period on \(refusal.stateID)")
            #expect(copy.recoveryLabel.count <= 20, "recovery label too long on \(refusal.stateID)")
            let row = ErrorState(stateID: refusal.stateID)
            #expect(row != nil, "\(refusal.stateID) has no registry row")
            #expect(row?.copy.title == copy.title, "title differs from the registry on \(refusal.stateID)")
            #expect(
                row?.copy.recoveryLabel == copy.recoveryLabel,
                "recovery label differs from the registry on \(refusal.stateID)"
            )

            for text in [copy.title, copy.body, copy.recoveryLabel] {
                #expect(!text.contains("!"), "exclamation mark in \(refusal.stateID)")
                #expect(!apologies.contains(where: text.lowercased().contains))
            }
        }
    }

    private func refusal(of text: String) -> KeyMaterialError? {
        do {
            _ = try KeyMaterialParser.parse(KeyMaterialBuffer(text: text))
            return nil
        } catch let error as KeyMaterialError {
            return error
        } catch {
            return nil
        }
    }
}
