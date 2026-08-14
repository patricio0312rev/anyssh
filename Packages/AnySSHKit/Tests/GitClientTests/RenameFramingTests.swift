import AnySSHCore
import Testing

@testable import GitClient

@Suite struct RenameFramingTests {
    private static let statusV2Record =
        "2 R. N... 100644 100644 100644 92f0830 92f0830 R100 "
        + "\0Sources/MetricsRenderer.swift\0Sources/LegacyRenderer.swift\0"
    private static let numstatRecord =
        "0\t0\t\0Sources/LegacyRenderer.swift\0Sources/MetricsRenderer.swift\0"

    @Test func bothParsersAgreeOnTheDoc08Rename() throws {
        let statusV2 = try RenameFraming.statusV2(record: Self.statusV2Record)
        let numstat = try RenameFraming.numstat(record: Self.numstatRecord)

        #expect(statusV2.oldPath == numstat.oldPath)
        #expect(statusV2.newPath == numstat.newPath)
        #expect(statusV2.oldPath == "Sources/LegacyRenderer.swift")
        #expect(statusV2.newPath == "Sources/MetricsRenderer.swift")
    }

    @Test func statusV2CarriesTheSimilarityScore() throws {
        let statusV2 = try RenameFraming.statusV2(record: Self.statusV2Record)
        #expect(statusV2.change == .renamed(similarity: 100))
        #expect(statusV2.isBinary == false)
    }

    @Test func statusV2RecordIsRejectedByTheNumstatParser() {
        #expect(throws: RenameFraming.ParseError.malformedRecord) {
            try RenameFraming.numstat(record: Self.statusV2Record)
        }
    }

    @Test func numstatRecordIsRejectedByTheStatusParser() {
        #expect(throws: RenameFraming.ParseError.malformedRecord) {
            try RenameFraming.statusV2(record: Self.numstatRecord)
        }
    }

    @Test func plainNumstatRecordIsNotARename() {
        let plain = "1\t0\ta.txt\0"
        #expect(throws: RenameFraming.ParseError.notARenameRecord) {
            try RenameFraming.numstat(record: plain)
        }
    }

    @Test func plainStatusV2RecordIsNotARename() {
        let plain =
            "1 MM N... 100644 100644 100644 "
            + "16686db857137893eeb7b60115b23ebe28bb8602 "
            + "f666eb165f8451a7ae7480cb28fc4b6022e5d0bd a.txt\0"
        #expect(throws: RenameFraming.ParseError.notARenameRecord) {
            try RenameFraming.statusV2(record: plain)
        }
    }

    @Test func mixedBinaryAndNumericCountsAreMalformed() {
        let mixed = "-\t3\t\0Assets/hero.png\0Assets/banner.png\0"
        #expect(throws: RenameFraming.ParseError.malformedRecord) {
            try RenameFraming.numstat(record: mixed)
        }
    }

    @Test func binaryRenameIsFlaggedFromTheNumstatMarker() throws {
        let binary = "-\t-\t\0Assets/hero.png\0Assets/banner.png\0"
        let parsed = try RenameFraming.numstat(record: binary)
        #expect(parsed.oldPath == "Assets/hero.png")
        #expect(parsed.newPath == "Assets/banner.png")
        #expect(parsed.isBinary)
    }

    @Test func garbageRecordIsMalformed() {
        #expect(throws: RenameFraming.ParseError.malformedRecord) {
            try RenameFraming.numstat(record: "not a record at all")
        }
        #expect(throws: RenameFraming.ParseError.malformedRecord) {
            try RenameFraming.statusV2(record: "not a record at all")
        }
    }
}
