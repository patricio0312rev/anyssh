import AVFoundation
import AnySSHCore
import Foundation
import Observation

@MainActor
@Observable
public final class VideoViewerModel {
    public enum State: Equatable {
        case loading
        case confirmation(Int)
        case playing
        case refusal(ErrorState)
        case failed(ErrorState)
    }

    public static let automaticLimit = 25 * 1024 * 1024
    public static let refusalLimit = 100 * 1024 * 1024
    public static let unsupportedExtensions: Set<String> = ["mkv", "webm"]

    public private(set) var state: State = .loading
    public private(set) var player: AVPlayer?

    private let ref: BlobRef
    private let service: any BlobService
    private var temporaryURL: URL?

    public init(ref: BlobRef, service: any BlobService) {
        self.ref = ref
        self.service = service
    }

    public func load() async {
        state = .loading
        guard Self.playableExtension(ref.path) else {
            state = .refusal(.files(.unsupportedVideo))
            return
        }
        do {
            guard let metadata = try await service.metadata(for: [ref]).first else {
                throw ErrorState.files(.fetchFailed)
            }
            guard metadata.byteCount <= Self.refusalLimit else {
                state = .refusal(.files(.blobTooLarge))
                return
            }
            if metadata.byteCount > Self.automaticLimit {
                state = .confirmation(metadata.byteCount)
                return
            }
            await download()
        } catch let error as ErrorState {
            state = .failed(error)
        } catch {
            state = .failed(.files(.fetchFailed))
        }
    }

    public func confirmDownload() async {
        await download()
    }

    public func dismiss() {
        player?.pause()
        player = nil
        if let temporaryURL { try? FileManager.default.removeItem(at: temporaryURL) }
        temporaryURL = nil
    }

    private func download() async {
        do {
            let blob = try await service.fetch(ref, intent: .video)
            let url = try Self.materialize(
                blob,
                extensionName: URL(fileURLWithPath: ref.path).pathExtension
            )
            temporaryURL = url
            player = AVPlayer(url: url)
            state = .playing
        } catch let error as ErrorState {
            state = .failed(error)
        } catch {
            state = .failed(.files(.fetchFailed))
        }
    }

    private static func playableExtension(_ path: String) -> Bool {
        !unsupportedExtensions.contains(URL(fileURLWithPath: path).pathExtension.lowercased())
    }

    private static func materialize(_ blob: FetchedBlob, extensionName: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(extensionName)
        switch blob.content {
        case .file(let source):
            try FileManager.default.moveItem(at: source, to: url)
        case .inMemory(let data):
            try data.write(to: url, options: .atomic)
        }
        return url
    }
}
