import AnySSHCore
import Foundation

public enum CapabilityProbeError: Error, Hashable, Sendable {
    case missingResponse
    case commandFailed(Int32)
    case malformedResponse(CapabilityParseError)
}

public struct SSHCapabilityProbe: CapabilityProbe {
    private let runner: any RemoteCommandRunner

    public init(runner: any RemoteCommandRunner) {
        self.runner = runner
    }

    public func probe() async throws -> HostCapabilities {
        let response = try await runner.run(CapabilityProbeCommand.batch())
        guard let section = response.sections.first(where: { $0.label == CapabilityProbeCommand.label })
        else { throw CapabilityProbeError.missingResponse }
        guard section.exitCode == 0 else {
            throw CapabilityProbeError.commandFailed(section.exitCode)
        }
        do {
            return try CapabilityParser().parse(section.bytes)
        } catch let error as CapabilityParseError {
            throw CapabilityProbeError.malformedResponse(error)
        }
    }
}
