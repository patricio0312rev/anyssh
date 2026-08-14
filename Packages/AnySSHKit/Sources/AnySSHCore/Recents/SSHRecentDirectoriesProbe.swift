import Foundation

public enum RecentDirectoriesProbeError: Error, Hashable, Sendable {
    case missingResponse
    case commandFailed(Int32)
    case malformedResponse(RecentDirectoriesParseError)
}

public struct SSHRecentDirectoriesProbe: RecentDirectoriesProbe {
    private let runner: any RemoteCommandRunner
    private let parser = RecentDirectoriesParser()

    public init(runner: any RemoteCommandRunner) {
        self.runner = runner
    }

    public func list(limit: Int = 40) async throws -> [RecentDirectory] {
        let batch = RecentDirectoriesCommand.batch(limit: limit)
        let response = try await runner.run(batch)
        guard
            let section = response.sections.first(where: {
                $0.label == RecentDirectoriesCommand.label
            })
        else {
            throw RecentDirectoriesProbeError.missingResponse
        }
        guard section.exitCode == 0 || section.exitCode == 141 else {
            throw RecentDirectoriesProbeError.commandFailed(section.exitCode)
        }
        do {
            return try parser.parse(section.bytes, limit: limit)
        } catch let error as RecentDirectoriesParseError {
            throw RecentDirectoriesProbeError.malformedResponse(error)
        }
    }
}
