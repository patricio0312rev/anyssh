import Foundation
import Security
import Testing

@testable import AnySSHCore

@Suite struct KeychainAttributeTests {
    private func attributes(_ reference: SecretReference) throws -> [String: Any] {
        try SecItemAttributes.add(KeychainItem.secret(reference), secret: KeychainFixture.keyMaterial)
    }

    @Test func theProtectionClassNeverSyncsAndNeverRestores() {
        #expect(SecItemAttributes.protection == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
    }

    @Test func everyUngatedItemCarriesThatProtectionClass() throws {
        for kind in SecretKind.allCases where kind.gate == .none {
            let written = try attributes(SecretReference(remoteID: KeychainFixture.remote, kind: kind))
            #expect(
                written[kSecAttrAccessible as String] as? String
                    == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
            )
            #expect(written[kSecAttrAccessControl as String] == nil)
        }
    }

    @Test func everyGatedItemCarriesAnAccessControlAndNoLooseAccessibility() throws {
        let gated = SecretKind.allCases.filter { $0.gate != .none }
        #expect(gated.map(\.rawValue).sorted() == ["keyPassphrase", "privateKey"])

        for kind in gated {
            let written = try attributes(SecretReference(remoteID: KeychainFixture.remote, kind: kind))
            let control = try #require(written[kSecAttrAccessControl as String])
            #expect(CFGetTypeID(control as CFTypeRef) == SecAccessControlGetTypeID())
            #expect(written[kSecAttrAccessible as String] == nil)
        }
    }

    @Test func theAccessControlIsBuiltFromTheSameProtectionClass() throws {
        let control = try SecItemAttributes.accessControl()

        #expect(CFGetTypeID(control) == SecAccessControlGetTypeID())
        #expect(SecItemAttributes.protection == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
    }

    @Test func everyItemIsAGenericPasswordThatNeverSynchronises() throws {
        for kind in SecretKind.allCases {
            let written = try attributes(SecretReference(remoteID: KeychainFixture.remote, kind: kind))
            #expect(written[kSecClass as String] as? String == kSecClassGenericPassword as String)
            #expect(written[kSecAttrSynchronizable as String] as? Bool == false)
            #expect(written[kSecAttrService as String] as? String == KeychainSchema.service)
        }
    }

    @Test func everyItemCarriesTheVersionStamp() throws {
        let written = try attributes(KeychainFixture.privateKey)

        #expect(written[kSecAttrGeneric as String] as? Data == KeychainSchema.stamp(1))
        #expect(KeychainSchema.version(of: written[kSecAttrGeneric as String] as? Data) == 1)
    }

    @Test func theVersionMarkerIsUngatedAndProtectedTheSameWay() throws {
        let written = try SecItemAttributes.add(.marker, secret: KeychainSchema.stamp(1))

        #expect(KeychainItem.marker.gate == .none)
        #expect(written[kSecAttrAccessControl as String] == nil)
        #expect(
            written[kSecAttrAccessible as String] as? String
                == kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
        )
        #expect(written[kSecAttrService as String] as? String == KeychainSchema.markerService)
    }

    @Test func noQueryEverCarriesAPayload() {
        let item = KeychainItem.secret(KeychainFixture.privateKey)
        let queries = [
            SecItemAttributes.query(item),
            SecItemAttributes.read(item),
            SecItemAttributes.search(service: KeychainSchema.service),
            SecItemAttributes.restamp(to: item),
        ]

        for query in queries {
            #expect(query[kSecValueData as String] == nil)
        }
        #expect(
            SecItemAttributes.search(service: KeychainSchema.service)[
                kSecReturnData as String
            ] == nil)
    }

    @Test func anAccountRoundTripsThroughItsReference() {
        let remotes = ["plain", "with.dots.everywhere", "🔑 emoji", "privateKey.looks-prefixed"]

        for remote in remotes {
            for kind in SecretKind.allCases {
                let reference = SecretReference(remoteID: RemoteID(rawValue: remote), kind: kind)
                let account = KeychainSchema.account(for: reference)
                #expect(KeychainSchema.reference(fromAccount: account) == reference)
            }
        }
    }

    @Test func anAccountThisBuildDidNotWriteParsesAsNothing() {
        #expect(KeychainSchema.reference(fromAccount: "bare") == nil)
        #expect(KeychainSchema.reference(fromAccount: "unknownKind.host") == nil)
        #expect(KeychainSchema.reference(fromAccount: "privateKey.") == nil)
        #expect(KeychainSchema.reference(fromAccount: "") == nil)
    }

    @Test func aStampThisBuildDidNotWriteReadsAsUnversioned() {
        #expect(KeychainSchema.version(of: nil) == 0)
        #expect(KeychainSchema.version(of: Data("1".utf8)) == 0)
        #expect(KeychainSchema.version(of: Data("anyssh/".utf8)) == 0)
        #expect(KeychainSchema.version(of: Data("anyssh/-3".utf8)) == 0)
        #expect(KeychainSchema.version(of: Data([0xff, 0xfe])) == 0)
        #expect(KeychainSchema.version(of: KeychainSchema.stamp(7)) == 7)
    }
}
