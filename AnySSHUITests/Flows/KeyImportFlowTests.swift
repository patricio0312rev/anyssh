import AnySSHCore
import AnySSHUI
import CryptoKit
import UIKit
import XCTest

@MainActor
final class KeyImportFlowTests: XCTestCase {
    private var pasteMonitor: NSObjectProtocol?

    override func setUp() {
        continueAfterFailure = false
        executionTimeAllowance = 120
        pasteMonitor = PastePermission.monitor(on: self)
    }

    override func tearDown() {
        if let pasteMonitor { removeUIInterruptionMonitor(pasteMonitor) }
        pasteMonitor = nil
    }

    func testPastingAKeyShowsItsFingerprintAndSavesIt() throws {
        let key = GeneratedKey()
        UIPasteboard.general.string = key.armoured
        let app = try launch()

        app.buttons[UIIdentifier.KeyImport.paste].tap()
        PastePermission.allow()

        let fingerprint = app.element(withIdentifier: UIIdentifier.KeyImport.fingerprint)
        XCTAssertTrue(fingerprint.waitForExistence(timeout: 5))
        XCTAssertEqual(fingerprint.value as? String, key.fingerprint)

        app.buttons[UIIdentifier.KeyImport.save].tap()
        let saved = app.element(withIdentifier: UIIdentifier.KeyImport.saved)
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        XCTAssertEqual(fingerprint.value as? String, key.fingerprint)
    }

    func testTheKeyIsOffThePasteboardAfterAnImport() throws {
        let key = GeneratedKey()
        UIPasteboard.general.string = key.armoured
        let app = try launch()

        app.buttons[UIIdentifier.KeyImport.paste].tap()
        PastePermission.allow()
        XCTAssertTrue(
            app.element(withIdentifier: UIIdentifier.KeyImport.fingerprint)
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(UIPasteboard.general.string?.contains("PRIVATE KEY") ?? false)
    }

    func testPastingAPublicKeyShowsTheNamedRefusal() throws {
        UIPasteboard.general.string = GeneratedKey().publicHalf
        let app = try launch()

        app.buttons[UIIdentifier.KeyImport.paste].tap()
        PastePermission.allow()

        let refusal = app.element(withIdentifier: "error.secrets.publicKeyOffered")
        XCTAssertTrue(refusal.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[KeyMaterialError.publicKeyOffered(.ed25519).copy.title].exists)
        XCTAssertFalse(app.buttons[UIIdentifier.KeyImport.save].exists)
    }

    private func launch() throws -> XCUIApplication {
        let app = XCUIApplication.launched(scenario: ScenarioName.empty)

        let importKey = app.buttons[UIIdentifier.Remote.emptyImportKey]
        XCTAssertTrue(
            importKey.waitForExistence(timeout: 10),
            "the zero-host state offered no import"
        )
        importKey.tap()

        XCTAssertTrue(
            app.buttons[UIIdentifier.KeyImport.paste].waitForExistence(timeout: 10),
            "the import route did not reach \(UIIdentifier.KeyImport.paste)"
        )
        return app
    }
}

private struct GeneratedKey {
    let armoured: String
    let fingerprint: String
    let publicHalf: String

    init() {
        let signing = Curve25519.Signing.PrivateKey()
        let publicKey = Array(signing.publicKey.rawRepresentation)
        let publicBlob = Self.field("ssh-ed25519") + Self.field(publicKey)

        let checksum = withUnsafeBytes(of: UInt32.random(in: 0...UInt32.max), Array.init)
        var section = checksum + checksum + publicBlob
        section += Self.field(Array(signing.rawRepresentation) + publicKey) + Self.field("anyssh")
        for index in 0..<((8 - section.count % 8) % 8) {
            section.append(UInt8(index + 1))
        }

        var body = Array("openssh-key-v1\u{0}".utf8)
        body += Self.field("none") + Self.field("none") + Self.field([UInt8]())
        body += withUnsafeBytes(of: UInt32(1).bigEndian, Array.init)
        body += Self.field(publicBlob) + Self.field(section)

        armoured = Self.armour(body)
        fingerprint =
            "SHA256:"
            + Data(SHA256.hash(data: Data(publicBlob))).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        publicHalf = "ssh-ed25519 \(Data(publicBlob).base64EncodedString()) anyssh"
    }

    private static func field(_ bytes: [UInt8]) -> [UInt8] {
        withUnsafeBytes(of: UInt32(bytes.count).bigEndian, Array.init) + bytes
    }

    private static func field(_ text: String) -> [UInt8] {
        field(Array(text.utf8))
    }

    private static func armour(_ body: [UInt8]) -> String {
        let encoded = Data(body).base64EncodedString()
        let wrapped = stride(from: 0, to: encoded.count, by: 70).map {
            String(encoded.dropFirst($0).prefix(70))
        }
        return
            (["-----BEGIN OPENSSH PRIVATE KEY-----"] + wrapped
            + ["-----END OPENSSH PRIVATE KEY-----"]).joined(separator: "\n")
    }
}
