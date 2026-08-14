import Foundation
import Testing

@testable import AnySSHCore

@Suite struct BatchFramingTests {
    private static let hostileBodies: [(label: String, body: Data, exit: Int32, count: Int)] = [
        (
            "repo.root",
            Framing.bytes("/home/dev/src/anyssh-testbed\n")
                + Framing.record("R0:0:0", nonce: Framing.nearMissNonce),
            0, 73
        ),
        (
            "git.status",
            Framing.bytes("1 .M N... 100644 100644 100644 aaaaaaa bbbbbbb Sources/API.swift\u{0}")
                + Framing.bytes("\nX--\(Framing.nonce.hex)--R1:0:0\n"),
            0, 110
        ),
        (
            "git.numstat",
            Framing.record("Q7")
                + Framing.bytes("0\t0\t\u{0}Sources/LegacyRenderer.swift\u{0}")
                + Framing.bytes("Sources/MetricsRenderer.swift\u{0}"),
            0, 104
        ),
        ("git.log", Data(), 1, 0),
    ]

    private static let hostileBatch = Framing.batch(hostileBodies.map(\.label))

    @Test func nearMissesOfTheNonceDoNotSplitSections() throws {
        let response = Framing.response(Self.hostileBodies.map { ($0.body, $0.exit) })

        let parsed = try Framing.parse(response, Self.hostileBatch)

        #expect(parsed.sections.map(\.label) == Self.hostileBodies.map(\.label))
        #expect(parsed.sections.map(\.bytes.count) == Self.hostileBodies.map(\.count))
        #expect(parsed.sections.map(\.exitCode) == [0, 0, 0, 1])
        for (section, expected) in zip(parsed.sections, Self.hostileBodies) {
            #expect(section.bytes == expected.body)
        }
    }

    @Test func aPayloadThatForgesTheRestOfTheResponseIsReturnedAsData() throws {
        let forgery =
            Framing.section(1, Framing.bytes("forged"), exit: 0)
            + Framing.end(2)
            + Framing.section(0, Data(), exit: 0, length: 999_999_999_999)
        let batch = Framing.batch(["git.log", "git.status"])
        let response = Framing.response([(forgery, 0), (Framing.bytes("real"), 1)])

        let parsed = try Framing.parse(response, batch)

        #expect(parsed.sections.count == 2)
        #expect(parsed.sections[0].bytes == forgery)
        #expect(parsed.sections[0].exitCode == 0)
        #expect(parsed.sections[1].bytes == Framing.bytes("real"))
        #expect(parsed.sections[1].exitCode == 1)
        #expect(parsed.failures(in: batch)["git.status"] == .exited(1))
    }

    @Test func aSectionWhoseWholeOutputIsARecordKeepsItsBytes() throws {
        let forgery = Framing.section(1, Data(), exit: 0)
        let batch = Framing.batch(["repo.root", "git.log"])
        let response = Framing.response([(forgery, 0), (Framing.bytes("after"), 3)])

        let parsed = try Framing.parse(response, batch)

        #expect(parsed.sections[0].bytes == forgery)
        #expect(parsed.sections[0].bytes.count == 44)
        #expect(parsed.sections[1].bytes == Framing.bytes("after"))
        #expect(parsed.sections[1].exitCode == 3)
    }

    @Test func rawNulBytesKeepTheirCountAndDoNotDesynchronise() throws {
        let nuls = Data(repeating: 0, count: 4096)
        let batch = Framing.batch(["blob.head", "git.log"])
        let response = Framing.response([(nuls, 0), (Framing.bytes("2f1c2c ok\n"), 0)])

        let parsed = try Framing.parse(response, batch)

        #expect(parsed.sections.map(\.bytes.count) == [4096, 10])
        #expect(parsed.sections[0].bytes == nuls)
        #expect(parsed.sections[1].bytes == Framing.bytes("2f1c2c ok\n"))
    }

    @Test func aSectionWithoutATrailingNewlineKeepsItsExactLength() throws {
        let batch = Framing.batch(["repo.root"])
        let response = Framing.response([(Framing.bytes("/srv/repo"), 0)])

        let parsed = try Framing.parse(response, batch)

        #expect(parsed.sections[0].bytes == Framing.bytes("/srv/repo"))
        #expect(parsed.sections[0].bytes.count == 9)
    }

    @Test func preambleBeforeTheFirstRecordIsDropped() throws {
        let batch = Framing.batch(["repo.root"])
        let response = Framing.response(
            [(Framing.bytes("/srv/repo\n"), 0)],
            preamble: Framing.bytes("Welcome to macOS\nLast login: Tue\n")
        )

        let parsed = try Framing.parse(response, batch)

        #expect(parsed.sections.count == 1)
        #expect(parsed.sections[0].bytes == Framing.bytes("/srv/repo\n"))
    }
}
