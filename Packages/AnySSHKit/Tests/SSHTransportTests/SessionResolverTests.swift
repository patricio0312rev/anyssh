import CSSH
import Darwin
import Foundation
import Testing

@testable import SSHTransport

@Suite struct SessionResolverTests {
    @Test func resolvesAnIPv6Literal() throws {
        let addresses = try AddressResolver.resolve(host: "::1", port: 22)
        let first = try #require(addresses.first)

        #expect(first.family == AF_INET6)
        #expect(first.literal == "::1")
        #expect(first.port == 22)
    }

    @Test func resolvesAnIPv4Literal() throws {
        let addresses = try AddressResolver.resolve(host: "127.0.0.1", port: 2222)
        let first = try #require(addresses.first)

        #expect(first.family == AF_INET)
        #expect(first.literal == "127.0.0.1")
    }

    @Test func offersEveryFamilyAHostAdvertises() throws {
        let families = Set(try AddressResolver.resolve(host: "localhost", port: 22).map(\.familyName))

        #expect(families.contains("AF_INET6"))
        #expect(families.contains("AF_INET"))
    }

    @Test func aNameThatCannotResolveCarriesItsErrorState() {
        #expect(throws: TransportFailure.resolutionFailed(host: "anyssh-nothing-here.invalid")) {
            try AddressResolver.resolve(host: "anyssh-nothing-here.invalid", port: 22)
        }
    }
}

@Suite struct SessionTailscaleSignatureTests {
    @Test func recognisesTheHangFollowedByAnAuthenticationError() {
        let failure = TailscaleSSHSignature.classify(
            elapsed: .seconds(61),
            code: LIBSSH2_ERROR_AUTHENTICATION_FAILED,
            onTailnetAddress: true,
            keyConfigurationLooksCorrect: true
        )

        #expect(failure == .tailscaleSSH)
        #expect(failure?.stateID == "transport.tailscaleSSH")
    }

    @Test func leavesAnImmediateRejectionAlone() {
        #expect(
            TailscaleSSHSignature.classify(
                elapsed: .milliseconds(400),
                code: LIBSSH2_ERROR_AUTHENTICATION_FAILED,
                onTailnetAddress: true,
                keyConfigurationLooksCorrect: true
            ) == nil
        )
    }

    @Test func leavesAKeyTheUserGotWrongAlone() {
        #expect(
            TailscaleSSHSignature.classify(
                elapsed: .seconds(70),
                code: LIBSSH2_ERROR_AUTHENTICATION_FAILED,
                onTailnetAddress: true,
                keyConfigurationLooksCorrect: false
            ) == nil
        )
    }

    @Test func leavesAHostOutsideTheTailnetAlone() {
        #expect(
            TailscaleSSHSignature.classify(
                elapsed: .seconds(70),
                code: LIBSSH2_ERROR_AUTHENTICATION_FAILED,
                onTailnetAddress: false,
                keyConfigurationLooksCorrect: true
            ) == nil
        )
    }

    @Test(
        arguments: [
            ("192.0.2.10", true),
            ("100.64.0.1", true),
            ("100.127.255.254", true),
            ("100.63.255.255", false),
            ("100.128.0.1", false),
            ("192.168.1.10", false),
            ("::1", false),
            ("100.64.999.999", false),
            ("100.64.0.256", false),
            ("100.64.0", false),
            ("100.64.0.1.2", false),
            ("100.64..1", false),
            ("100.64.0.+1", false),
            ("100.64.0.0x1", false),
        ])
    func readsTheCarrierGradeRange(literal: String, isTailnet: Bool) {
        #expect(TailscaleSSHSignature.isTailnetAddress(literal) == isTailnet)
    }
}
