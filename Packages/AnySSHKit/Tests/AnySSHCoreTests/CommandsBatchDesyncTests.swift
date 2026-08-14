import Foundation
import Testing

@testable import AnySSHCore

@Suite struct BatchDesynchronisationTests {
    @Test func aCountThatUndersellsItsSectionIsCaughtAtTheNextRecord() throws {
        let batch = Framing.batch(["repo.root", "git.log"])
        let response =
            Framing.section(0, Framing.bytes("/srv/repo\n"), exit: 0, length: 4)
            + Framing.section(1, Data(), exit: 0)
            + Framing.end(2)

        #expect(throws: BatchFramingError.desynchronised(label: "git.log")) {
            try Framing.parse(response, batch)
        }
    }

    @Test func aCountThatOverrunsItsSectionIsCaughtAtTheNextRecord() throws {
        let batch = Framing.batch(["repo.root", "git.log"])
        let response =
            Framing.section(0, Framing.bytes("/srv/repo\n"), exit: 0, length: 24)
            + Framing.section(1, Data(), exit: 0)
            + Framing.end(2)

        #expect(throws: BatchFramingError.desynchronised(label: "git.log")) {
            try Framing.parse(response, batch)
        }
    }

    @Test func aStreamThatStopsMidSectionThrowsRatherThanReturningWhatItHad() throws {
        let batch = Framing.batch(["repo.root", "git.log"])
        let complete = Framing.response([(Framing.bytes("/srv/repo\n"), 0), (Data(), 0)])

        #expect(throws: BatchFramingError.unterminatedSection(label: "git.log")) {
            try Framing.parse(Data(complete.prefix(complete.count - 20)), batch)
        }
    }

    @Test func bytesAfterTheClosingRecordAreRefused() throws {
        let batch = Framing.batch(["repo.root"])
        let response =
            Framing.response([(Framing.bytes("/srv/repo\n"), 0)])
            + Framing.section(1, Framing.bytes("extra"), exit: 0)

        #expect(throws: BatchFramingError.trailingBytes(label: "repo.root")) {
            try Framing.parse(response, batch)
        }
    }

    @Test func aResponseForADifferentRequestDoesNotParse() throws {
        let batch = Framing.batch(["repo.root"])
        let response = Framing.response([(Framing.bytes("/srv/repo\n"), 0)])
        let other = BatchResponseParser(nonce: BatchNonce(), batch: batch)

        #expect(throws: BatchFramingError.missingSection(label: "repo.root")) {
            try other.parse(response)
        }
    }

    @Test func recordsArrivingOutOfOrderDesynchronise() throws {
        let batch = Framing.batch(["repo.root", "git.log"])
        let response = Framing.section(1, Framing.bytes("out of order"), exit: 0) + Framing.end(2)

        #expect(throws: BatchFramingError.desynchronised(label: "repo.root")) {
            try Framing.parse(response, batch)
        }
    }

    @Test func aClosingRecordCountingTheWrongNumberOfSectionsDesynchronises() throws {
        let batch = Framing.batch(["repo.root", "git.log"])
        let response = Framing.section(0, Data(), exit: 0) + Framing.end(1)

        #expect(throws: BatchFramingError.desynchronised(label: "git.log")) {
            try Framing.parse(response, batch)
        }
    }

    @Test func anEmptyBatchParsesFromTheClosingRecordAlone() throws {
        let parsed = try Framing.parse(Framing.end(0), RemoteBatch(commands: []))

        #expect(parsed.sections.isEmpty)
    }
}
