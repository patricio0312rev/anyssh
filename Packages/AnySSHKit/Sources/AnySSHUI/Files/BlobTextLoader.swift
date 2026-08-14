import AnySSHCore
import Foundation
import Observation

@MainActor
@Observable
public final class BlobTextLoader {
    public enum State: Equatable {
        case loading
        case refusal(ErrorState)
        case loaded(String)
        case failed(ErrorState)
    }

    public private(set) var state: State = .loading
    public private(set) var byteCount = 0

    private let ref: BlobRef
    private let service: any BlobService
    private let intent: BlobIntent
    private let cap: Int
    private var openAnywayRequested = false

    public init(ref: BlobRef, service: any BlobService, cap: Int, intent: BlobIntent = .source) {
        self.ref = ref
        self.service = service
        self.intent = intent
        self.cap = cap
    }

    public func load() async {
        state = .loading
        do {
            let metadata = try await service.metadata(for: [ref]).first
            guard let metadata else { throw ErrorState.files(.fetchFailed) }
            byteCount = metadata.byteCount
            guard metadata.byteCount <= cap || openAnywayRequested else {
                state = .refusal(.files(.blobTooLarge))
                return
            }
            let blob = try await service.fetch(ref, intent: intent)
            guard case .inMemory(let bytes) = blob.content else {
                state = .failed(.files(.blobTooLarge))
                return
            }
            state = .loaded(String(decoding: bytes, as: UTF8.self))
        } catch let error as ErrorState {
            state = .failed(error)
        } catch {
            state = .failed(.files(.fetchFailed))
        }
    }

    public func allowOverCap() {
        openAnywayRequested = true
    }
}
