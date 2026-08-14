#if canImport(UIKit)
import AnySSHCore
import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
public final class ImageViewerModel {
    public enum State {
        case loading
        case loaded(CGImage)
        case failed(ErrorState)
    }

    public static let cap = 25 * 1024 * 1024
    public static let defaultMaxPixelSize = 1_600

    public private(set) var state: State = .loading
    private let ref: BlobRef
    private let service: any BlobService
    private let decoder: ImageThumbnailDecoder
    private let maxPixelSize: Int

    public init(
        ref: BlobRef,
        service: any BlobService,
        maxPixelSize: Int = ImageViewerModel.defaultMaxPixelSize,
        decoder: ImageThumbnailDecoder = ImageThumbnailDecoder()
    ) {
        self.ref = ref
        self.service = service
        self.maxPixelSize = maxPixelSize
        self.decoder = decoder
    }

    public func load() async {
        state = .loading
        do {
            let metadata = try await service.metadata(for: [ref]).first
            guard let metadata, metadata.byteCount <= Self.cap else {
                state = .failed(.files(.blobTooLarge))
                return
            }
            guard case .inMemory(let data) = try await service.fetch(ref, intent: .image).content,
                let image = decoder.decode(data, maxPixelSize: maxPixelSize)
            else {
                state = .failed(.files(.imageDecodeFailed))
                return
            }
            state = .loaded(image)
        } catch let error as ErrorState {
            state = .failed(error)
        } catch {
            state = .failed(.files(.fetchFailed))
        }
    }
}
#endif
