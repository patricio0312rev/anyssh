import AnySSHCore
import Foundation

public actor RemoteBlobService: BlobService, FileTreeService {
    private let runner: any RemoteCommandRunner
    private let fetcher: any RawBlobFetcher
    private let root: URL
    private let memoryThreshold: Int
    private let lfsDetector = LFSDetector()

    public init(
        runner: any RemoteCommandRunner,
        fetcher: any RawBlobFetcher,
        root: URL = FileManager.default.temporaryDirectory,
        memoryThreshold: Int = 256 * 1024
    ) {
        self.runner = runner
        self.fetcher = fetcher
        self.root = root.appendingPathComponent("AnySSH", isDirectory: true)
        self.memoryThreshold = memoryThreshold
    }

    public func metadata(for refs: [BlobRef]) async throws -> [BlobMetadata] {
        guard !refs.isEmpty else { return [] }
        let commands = refs.map {
            RemoteCommand(
                label: $0.objectID, arguments: ["git", "cat-file", "--batch-check", "-Z", $0.objectID])
        }
        let response = try await runner.run(RemoteBatch(commands: commands))
        return try response.sections.map(Self.metadata)
    }

    public func tree(repository: RepositoryRef, ref: String) async throws -> FileTree {
        let command = RemoteCommand(
            label: "tree",
            arguments: ["git", "-C", repository.root, "ls-tree", "-z", ref]
        )
        let response = try await runner.run(RemoteBatch(commands: [command]))
        guard let section = response.sections.first else { throw Failure.invalidMetadata }
        return try LsTreeParser().parse(section.bytes)
    }

    public func fetch(_ ref: BlobRef, intent: BlobIntent) async throws -> FetchedBlob {
        let metadata = try await metadata(for: [ref]).first ?? { throw Failure.invalidMetadata }()
        guard metadata.type == "blob" else { throw Failure.invalidMetadata }
        let limit = BlobLimit(intent: intent).byteCount
        guard metadata.byteCount <= limit else { throw ErrorState.files(.blobTooLarge) }
        try Task.checkCancellation()
        let channel = try await fetcher.openBlobChannel(repository: ref.repository, objectID: ref.objectID)
        do {
            let result = try await receive(
                ref: ref,
                channel: channel,
                expected: metadata.byteCount,
                cap: min(metadata.byteCount, limit)
            )
            await channel.close()
            if case .inMemory(let bytes) = result.content, lfsDetector.isPointer(bytes) {
                throw ErrorState.files(.lfsPointer)
            }
            return result
        } catch {
            await channel.close()
            throw error
        }
    }

    public func sweepTemporaryFiles() throws {
        guard FileManager.default.fileExists(atPath: root.path) else { return }
        try FileManager.default.removeItem(at: root)
    }

    private func receive(
        ref: BlobRef,
        channel: any RawBlobChannel,
        expected: Int,
        cap: Int
    ) async throws -> FetchedBlob {
        var memory = Data()
        var fileURL: URL?
        var handle: FileHandle?
        var completed = false
        var written = 0
        defer {
            try? handle?.close()
            if !completed, let fileURL { try? FileManager.default.removeItem(at: fileURL) }
        }
        while let chunk = try await channel.receive() {
            try Task.checkCancellation()
            written += chunk.count
            guard written <= cap else { throw ErrorState.files(.blobTooLarge) }
            if fileURL == nil, memory.count + chunk.count <= memoryThreshold {
                memory.append(chunk)
            } else {
                if fileURL == nil {
                    let url = try makeTempURL(for: ref.path)
                    fileURL = url
                    handle = try FileHandle(forWritingTo: url)
                    try handle?.write(contentsOf: memory)
                    memory.removeAll(keepingCapacity: false)
                }
                try handle?.write(contentsOf: chunk)
            }
        }
        let count =
            fileURL == nil
            ? memory.count
            : Int(
                (try? FileManager.default.attributesOfItem(atPath: fileURL!.path)[.size] as? NSNumber)?
                    .intValue ?? 0)
        guard count == expected else { throw Failure.incompleteTransfer }
        completed = true
        return FetchedBlob(
            ref: ref,
            content: fileURL.map(BlobContent.file) ?? .inMemory(memory),
            byteCount: count,
            truncated: false
        )
    }

    private func makeTempURL(for path: String) throws -> URL {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let extensionName = URL(fileURLWithPath: path).pathExtension
        let name = UUID().uuidString + (extensionName.isEmpty ? "" : "." + extensionName)
        let url = root.appendingPathComponent(name)
        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            throw Failure.invalidMetadata
        }
        return url
    }

    private static func metadata(_ section: CommandSection) throws -> BlobMetadata {
        let fields = String(decoding: section.bytes, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
        guard fields.count >= 3, let size = Int(fields[2]) else { throw Failure.invalidMetadata }
        return BlobMetadata(objectID: String(fields[0]), type: String(fields[1]), byteCount: size)
    }

    public enum Failure: Error, Sendable, Equatable {
        case invalidMetadata
        case incompleteTransfer
    }
}
