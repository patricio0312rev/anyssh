import AnySSHCore
import Foundation

public struct MockRemoteFileBrowser: RemoteFileBrowser {
    public enum Scenario: String, Sendable, CaseIterable {
        case populated
        case truncated
        case unreachable
    }

    private let scenario: Scenario
    private let delay: Duration

    public init(_ scenario: Scenario = .populated, delay: Duration = .zero) {
        self.scenario = scenario
        self.delay = delay
    }

    public func list(path: String) async throws -> DirectoryListing {
        try await pause()
        guard scenario != .unreachable else { throw ErrorState.files(.fetchFailed) }
        guard let listing = FileFixtures.listings[path] else {
            return DirectoryListing(path: path, entries: [])
        }
        guard scenario == .truncated else { return listing }
        return DirectoryListing(path: path, entries: listing.entries, isTruncated: true)
    }

    public func read(path: String) async throws -> FileContentCommand.Content {
        try await pause()
        guard scenario != .unreachable else { throw ErrorState.files(.fetchFailed) }
        if path.hasSuffix(".png") {
            return FileContentCommand.Content(
                bytes: ImageFixtures.before,
                byteCount: ImageFixtures.before.count
            )
        }
        guard let text = FileFixtures.contents[path] else {
            throw ErrorState.files(.fetchFailed)
        }
        let bytes = Data(text.utf8)
        return FileContentCommand.Content(bytes: bytes, byteCount: bytes.count)
    }

    private func pause() async throws {
        guard delay > .zero else { return }
        try await Task.sleep(for: delay)
    }
}
