import AnySSHCore
import AnySSHMocks
import Foundation
import Testing

@testable import AnySSHUI

@Suite @MainActor struct FilesSourceModelTests {
    @Test func smallFileLoadsIntoContent() async throws {
        let payload = "let answer = 42\n"
        let model = makeModel(byteCount: payload.utf8.count, payload: payload)

        await model.load()

        guard case .content(let document) = model.state else {
            Issue.record("expected content, got \(model.state)")
            return
        }
        #expect(document.text == payload)
        #expect(document.byteCount == payload.utf8.count)
        #expect(document.tokens.isEmpty == false)
    }

    @Test func overCapFileRefusesBeforeFetching() async {
        let service = ScriptedBlobService(byteCount: 3 * 1024 * 1024, payload: Data())
        let model = makeModel(service: service)

        await model.load()

        #expect(model.state == .refusal(.files(.blobTooLarge)))
        #expect(await service.fetchCount == 0)
    }

    @Test func openAnywayLoadsAnOverCapFile() async {
        let payload = "let big = true\n"
        let service = ScriptedBlobService(
            byteCount: 3 * 1024 * 1024,
            payload: Data(payload.utf8)
        )
        let model = makeModel(service: service)

        await model.load()
        #expect(model.state == .refusal(.files(.blobTooLarge)))

        await model.openAnyway()

        guard case .content(let document) = model.state else {
            Issue.record("expected content after open anyway, got \(model.state)")
            return
        }
        #expect(document.text == payload)
    }

    @Test func failedFetchShowsTheRegistryFailure() async {
        let service = ScriptedBlobService(byteCount: 10, payload: Data(), throwsOnFetch: true)
        let model = makeModel(service: service)

        await model.load()

        #expect(model.state == .failed(.files(.fetchFailed)))
    }

    private func makeModel(byteCount: Int, payload: String) -> SourceViewerModel {
        makeModel(service: ScriptedBlobService(byteCount: byteCount, payload: Data(payload.utf8)))
    }

    private func makeModel(service: ScriptedBlobService) -> SourceViewerModel {
        SourceViewerModel(
            ref: BlobRef(
                repository: RepositoryRef(
                    remoteID: RemoteID(rawValue: "r"),
                    root: "/repo",
                    gitDir: "/repo/.git"
                ),
                objectID: "abc",
                path: "sample.swift"
            ),
            service: service,
            highlighter: MockSyntaxHighlighter(),
            language: .swift
        )
    }
}

private actor ScriptedBlobService: BlobService {
    let byteCount: Int
    let payload: Data
    var throwsOnFetch = false
    private(set) var fetchCount = 0

    init(byteCount: Int, payload: Data, throwsOnFetch: Bool = false) {
        self.byteCount = byteCount
        self.payload = payload
        self.throwsOnFetch = throwsOnFetch
    }

    func metadata(for refs: [BlobRef]) async throws -> [BlobMetadata] {
        refs.map { ref in
            BlobMetadata(objectID: ref.objectID, type: "blob", byteCount: byteCount)
        }
    }

    func fetch(_ ref: BlobRef, intent: BlobIntent) async throws -> FetchedBlob {
        fetchCount += 1
        if throwsOnFetch {
            throw ErrorState.files(.fetchFailed)
        }
        return FetchedBlob(
            ref: ref,
            content: .inMemory(payload),
            byteCount: payload.count,
            truncated: false
        )
    }
}
