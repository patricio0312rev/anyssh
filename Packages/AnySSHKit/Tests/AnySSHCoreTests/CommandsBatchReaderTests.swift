import Foundation
import Testing

@testable import AnySSHCore

@Suite struct BatchReaderTests {
    private static let batch = Framing.batch(["repo.root", "git.status", "git.log"])

    private static let forgery =
        Framing.section(2, Framing.bytes("forged"), exit: 0) + Framing.end(3)

    private static let response = Framing.response([
        (Framing.bytes("/srv/repo\n"), 0),
        (forgery, 0),
        (Data(repeating: 0, count: 300), 1),
    ])

    @Test func aResponseSplitAtEveryByteParsesIdentically() throws {
        let expected = try read([Self.response])

        for split in 0...Self.response.count {
            let head = Data(Self.response.prefix(split))
            let tail = Data(Self.response.dropFirst(split))

            let parsed = try read([head, tail])

            #expect(parsed == expected, "split at \(split)")
        }
    }

    @Test func aResponseFedOneByteAtATimeParsesIdentically() throws {
        let parsed = try read(Self.chunked(Self.response, size: 1))

        #expect(parsed == (try read([Self.response])))
        #expect(parsed.sections.map(\.bytes.count) == [10, 90, 300])
        #expect(parsed.sections[1].bytes == Self.forgery)
    }

    @Test func chunkSizesThatCutAcrossRecordsAndBodiesAllAgree() throws {
        let expected = try read([Self.response])

        for size in [2, 3, 7, 36, 37, 38, 64, 1024] {
            let parsed = try read(Self.chunked(Self.response, size: size))

            #expect(parsed == expected, "chunk size \(size)")
        }
    }

    @Test func aResponseThatPassesTheBoundIsRefused() throws {
        let batch = Framing.batch(["git.log"])
        let flood = Framing.section(0, Data(repeating: 0x41, count: 8192), exit: 0)

        #expect(throws: BatchFramingError.responseTooLarge(label: "git.log", limit: 4096)) {
            try read(Self.chunked(flood, size: 512), batch, .init(maximumResponseBytes: 4096))
        }
    }

    @Test func aSectionDeclaringMoreThanTheBoundIsRefusedBeforeItsBytesArrive() throws {
        let batch = Framing.batch(["git.log"])
        let header = Framing.section(0, Data(), exit: 0, length: 1 << 30)

        #expect(throws: BatchFramingError.responseTooLarge(label: "git.log", limit: 4096)) {
            try read([header], batch, .init(maximumResponseBytes: 4096))
        }
    }

    @Test func anEndlessBannerIsRefusedAtTheSameBound() throws {
        let batch = Framing.batch(["git.log"])
        let banner = Data(repeating: 0x2E, count: 5000)

        #expect(throws: BatchFramingError.responseTooLarge(label: "git.log", limit: 4096)) {
            try read(Self.chunked(banner, size: 1000), batch, .init(maximumResponseBytes: 4096))
        }
    }

    @Test func aResponseThatFitsTheBoundExactlyStillParses() throws {
        let batch = Framing.batch(["git.log"])
        let response = Framing.response([(Framing.bytes("ok\n"), 0)])

        let parsed = try read([response], batch, .init(maximumResponseBytes: response.count))

        #expect(parsed.sections[0].bytes == Framing.bytes("ok\n"))
    }

    @Test func aReaderThatNeverSawTheClosingRecordThrowsOnFinish() throws {
        let batch = Framing.batch(["git.log"])
        let response = Framing.section(0, Framing.bytes("ok\n"), exit: 0)

        #expect(throws: BatchFramingError.unterminatedSection(label: "git.log")) {
            try read(Self.chunked(response, size: 5), batch)
        }
    }

    private func read(
        _ chunks: [Data],
        _ batch: RemoteBatch = BatchReaderTests.batch,
        _ limits: BatchLimits = .default
    ) throws -> BatchResponse {
        var reader = BatchResponseParser(nonce: Framing.nonce, batch: batch, limits: limits).reader()
        for chunk in chunks { try reader.append(chunk) }
        return try reader.finish()
    }

    private static func chunked(_ data: Data, size: Int) -> [Data] {
        stride(from: 0, to: data.count, by: size).map {
            Data(data[(data.startIndex + $0)..<min(data.startIndex + $0 + size, data.endIndex)])
        }
    }
}
