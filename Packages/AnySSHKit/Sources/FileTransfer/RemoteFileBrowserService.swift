import AnySSHCore
import Foundation

public actor RemoteFileBrowserService: RemoteFileBrowser {
    private let runner: any RemoteCommandRunner

    public init(runner: any RemoteCommandRunner) {
        self.runner = runner
    }

    public func list(path: String) async throws -> DirectoryListing {
        let response = try await runner.run(DirectoryListingCommand.batch(path: path))
        guard let section = response.sections.first else { throw ErrorState.files(.fetchFailed) }
        return DirectoryListingCommand.parse(section.bytes, path: path)
    }

    public func read(path: String) async throws -> FileContentCommand.Content {
        let response = try await runner.run(FileContentCommand.batch(path: path))
        guard let section = response.sections.first else { throw ErrorState.files(.fetchFailed) }
        do {
            return try FileContentCommand.parse(section.bytes)
        } catch FileContentCommand.Failure.notAFile {
            throw ErrorState.files(.fetchFailed)
        }
    }
}
