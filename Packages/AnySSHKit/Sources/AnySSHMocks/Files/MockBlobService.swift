import AnySSHCore
import Foundation

public struct MockBlobService: BlobService {
    public enum Scenario: String, Sendable, CaseIterable {
        case available
        case overCap
        case unreachable
    }

    public static let overCapByteCount = 3 * 1024 * 1024

    private let scenario: Scenario
    private let payloads: [String: Data]
    private let byteCountOverride: Int?

    public init(
        _ scenario: Scenario = .available,
        payloads: [String: Data] = MockBlobService.defaultPayloads,
        byteCount: Int? = nil
    ) {
        self.scenario = scenario
        self.payloads = payloads
        self.byteCountOverride = byteCount
    }

    public static let defaultPayloads: [String: Data] = [
        "Package.swift": Data(FileFixtures.swiftSource.utf8),
        "config.json": Data(FileFixtures.jsonSource.utf8),
        "README.md": Data(FileFixtures.markdownSource.utf8),
        "icon.svg": Data(FileFixtures.svgSource.utf8),
        "before.png": ImageFixtures.before,
        "after.png": ImageFixtures.after,
    ]

    public func metadata(for refs: [BlobRef]) async throws -> [BlobMetadata] {
        guard scenario != .unreachable else { throw ErrorState.files(.fetchFailed) }
        return refs.map { ref in
            BlobMetadata(objectID: ref.objectID, type: "blob", byteCount: byteCount(for: ref))
        }
    }

    public func fetch(_ ref: BlobRef, intent: BlobIntent) async throws -> FetchedBlob {
        guard scenario != .unreachable else { throw ErrorState.files(.fetchFailed) }
        let payload = payload(for: ref)
        return FetchedBlob(
            ref: ref,
            content: .inMemory(payload),
            byteCount: payload.count,
            truncated: false
        )
    }

    private func byteCount(for ref: BlobRef) -> Int {
        if let byteCountOverride { return byteCountOverride }
        return scenario == .overCap ? Self.overCapByteCount : payload(for: ref).count
    }

    private func payload(for ref: BlobRef) -> Data {
        payloads[(ref.path as NSString).lastPathComponent] ?? Data()
    }
}
