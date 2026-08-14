import AnySSHCore
import Foundation
import Testing

@testable import FileTransfer

@Suite struct RemoteBlobServiceCapTests {
    @Test func abortsWhenTheStreamRunsPastTheClaimedSize() async throws {
        let claimed = 200
        let chunkSize = 64
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let channel = StreamingChannel(chunkSize: chunkSize, chunks: 100)
        let service = RemoteBlobService(
            runner: MetadataRunner(objectID: "deadbeef", byteCount: claimed),
            fetcher: SingleChannelFetcher(channel: channel),
            root: root,
            memoryThreshold: chunkSize
        )
        let ref = BlobRef(
            repository: RepositoryRef(remoteID: RemoteID(rawValue: "r"), root: "/repo", gitDir: "/repo/.git"),
            objectID: "deadbeef",
            path: "blob.bin"
        )

        await #expect(throws: ErrorState.files(.blobTooLarge)) {
            _ = try await service.fetch(ref, intent: .diffSide)
        }

        let emitted = await channel.bytesEmitted
        #expect(emitted <= claimed + chunkSize)

        let spillDir = root.appendingPathComponent("AnySSH", isDirectory: true)
        let leftovers = (try? FileManager.default.contentsOfDirectory(atPath: spillDir.path)) ?? []
        #expect(leftovers.isEmpty)
    }
}

private struct MetadataRunner: RemoteCommandRunner {
    let objectID: String
    let byteCount: Int

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        BatchResponse(
            sections: batch.commands.map { command in
                CommandSection(
                    label: command.label,
                    bytes: Data("\(objectID) blob \(byteCount)".utf8),
                    exitCode: 0,
                    truncated: false
                )
            })
    }
}

private struct SingleChannelFetcher: RawBlobFetcher {
    let channel: StreamingChannel

    func openBlobChannel(repository: RepositoryRef, objectID: String) async throws -> any RawBlobChannel {
        channel
    }
}

private actor StreamingChannel: RawBlobChannel {
    private let chunkSize: Int
    private var remaining: Int
    private(set) var bytesEmitted = 0

    init(chunkSize: Int, chunks: Int) {
        self.chunkSize = chunkSize
        self.remaining = chunks
    }

    func receive() async throws -> Data? {
        guard remaining > 0 else { return nil }
        remaining -= 1
        bytesEmitted += chunkSize
        return Data(count: chunkSize)
    }

    func close() async {}
}
