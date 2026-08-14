import AnySSHCore
import Foundation

@testable import SSHTransport

final class CapabilityRoundTripCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int { lock.withLock { count } }

    func recordChannelOpen() {
        lock.withLock { count += 1 }
    }
}

struct LiveCapabilityBatchRunner: RemoteCommandRunner {
    let host: LiveHost
    let counter: CapabilityRoundTripCounter

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        let rendered = BatchScriptBuilder().render(batch)
        counter.recordChannelOpen()
        let outcome = try LiveSSHProbe(host: host).run(command: rendered.command)
        return try BatchResponseParser(nonce: rendered.nonce, batch: batch)
            .parse(Data(outcome.output.utf8))
    }
}

func runLiveCapabilityProbe(loginShell: Bool) throws -> HostCapabilities {
    let batch = CapabilityProbeCommand.batch()
    let rendered = BatchScriptBuilder().render(batch)
    let command = loginShell ? rendered.command : rendered.script
    let outcome = try LiveSSHProbe(host: .development).run(command: command)
    let response = try BatchResponseParser(nonce: rendered.nonce, batch: batch)
        .parse(Data(outcome.output.utf8))
    guard let section = response.sections.first,
        section.exitCode == 0
    else { throw CapabilityProbeError.missingResponse }
    return try CapabilityParser().parse(section.bytes)
}

func liveCapabilityDictionary(_ value: HostCapabilities) -> [String: Any] {
    [
        "shell": value.shell,
        "platform": value.platform,
        "locale": value.locale,
        "home": value.home,
        "path": value.searchPath,
        "git": ["path": value.git.path ?? "", "version": value.git.version ?? ""],
        "tmux": ["path": value.tmux.path ?? "", "version": value.tmux.version ?? ""],
        "herdr": [
            "path": value.herdr.tool.path ?? "",
            "version": value.herdr.tool.version ?? "",
            "protocol": value.herdr.protocolVersion.map { $0 as Any } ?? NSNull(),
        ],
    ]
}
