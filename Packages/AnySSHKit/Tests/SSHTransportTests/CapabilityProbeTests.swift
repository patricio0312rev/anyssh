import Foundation
import Testing

@testable import SSHTransport

@Suite struct CapabilityProbeTests {
    @Test func probeUsesOneCommandInsideOneBatch() async throws {
        let runner = CapabilityRecordingRunner(bytes: CapabilityFixtureData.gitOnly)
        let value = try await SSHCapabilityProbe(runner: runner).probe()

        #expect(value.git.path == "/usr/bin/git")
        #expect(runner.batches.count == 1)
        #expect(runner.batches[0].commands.count == 1)
        #expect(runner.batches[0].commands[0].label == CapabilityProbeCommand.label)
        #expect(runner.batches[0].commands[0].arguments[0] == "sh")
    }

    @Test func commandContainsNoSecondLoginShellWrapper() {
        let command = CapabilityProbeCommand.batch().commands[0]
        #expect(command.arguments.count == 3)
        #expect(command.arguments[2].contains("anyssh-capabilities/1"))
    }
}
