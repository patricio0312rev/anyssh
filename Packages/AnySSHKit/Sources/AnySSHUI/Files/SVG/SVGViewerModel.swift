#if canImport(UIKit)
import AnySSHCore
import Foundation
import Observation
import SwiftDraw
import UIKit

@MainActor
@Observable
public final class SVGViewerModel {
    public enum State: Equatable {
        case loading
        case refusal(ErrorState)
        case fallback(ErrorState)
        case content
        case failed(ErrorState)
    }

    public static let cap = 256 * 1024
    public static let parseBudget = Duration.seconds(1)

    public private(set) var state: State = .loading
    public private(set) var image: UIImage?
    public private(set) var source = ""

    private let ref: BlobRef
    private let service: any BlobService

    public init(ref: BlobRef, service: any BlobService) {
        self.ref = ref
        self.service = service
    }

    public func load() async {
        state = .loading
        do {
            guard let metadata = try await service.metadata(for: [ref]).first else {
                throw ErrorState.files(.fetchFailed)
            }
            guard metadata.byteCount <= Self.cap else {
                source = try Self.text(from: try await service.fetch(ref, intent: .source))
                state = .refusal(.files(.svgTooLarge))
                return
            }
            source = try Self.text(from: try await service.fetch(ref, intent: .svg))
            guard let svg = try await Self.parse(Data(source.utf8)) else {
                state = .fallback(.files(.svgParseFailed))
                return
            }
            image = svg.rasterize()
            state = .content
        } catch is Timeout {
            state = .fallback(.files(.svgParseFailed))
        } catch let error as ErrorState {
            state = .failed(error)
        } catch {
            state = .failed(.files(.fetchFailed))
        }
    }

    private static func text(from blob: FetchedBlob) throws -> String {
        guard case .inMemory(let data) = blob.content else {
            throw ErrorState.files(.fetchFailed)
        }
        return String(decoding: data, as: UTF8.self)
    }

    private static func parse(_ data: Data) async throws -> SVG? {
        try await withThrowingTaskGroup(of: SVG?.self) { group in
            group.addTask { SVG(data: data) }
            group.addTask {
                try await Task.sleep(for: parseBudget)
                throw Timeout()
            }
            defer { group.cancelAll() }
            return try await group.next() ?? nil
        }
    }

    private struct Timeout: Error {}
}
#endif
