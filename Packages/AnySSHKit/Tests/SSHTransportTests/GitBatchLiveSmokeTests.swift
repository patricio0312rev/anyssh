import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: LiveHost.isDevelopmentHostReachable))
struct GitBatchLiveSmokeTests {
    @Test func everyCommandInABatchComesBackAsItsOwnSection() async throws {
        let batch = RemoteBatch(commands: [
            RemoteCommand(label: "first", arguments: ["sh", "-c", "printf one"]),
            RemoteCommand(label: "second", arguments: ["sh", "-c", "printf two"]),
            RemoteCommand(label: "third", arguments: ["sh", "-c", "printf three"]),
        ])

        let response = try await LiveCapabilityBatchRunner(
            host: .development, counter: CapabilityRoundTripCounter()
        ).run(batch)

        #expect(response.sections.map(\.label) == ["first", "second", "third"])
        #expect(
            response.sections.map { String(decoding: $0.bytes, as: UTF8.self) } == ["one", "two", "three"])
    }

    @Test func aSilentCommandStillGetsASection() async throws {
        let batch = RemoteBatch(commands: [
            RemoteCommand(label: "loud", arguments: ["sh", "-c", "printf hello"]),
            RemoteCommand(label: "silent", arguments: ["sh", "-c", "true"]),
        ])

        let response = try await LiveCapabilityBatchRunner(
            host: .development, counter: CapabilityRoundTripCounter()
        ).run(batch)

        #expect(response.sections.map(\.label) == ["loud", "silent"])
        #expect(response.sections.last?.bytes.isEmpty == true)
    }
}
