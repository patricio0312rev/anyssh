#if os(macOS)
import AnySSHCore
import Foundation
import Testing

@testable import Multiplexers

@Suite(.enabled(if: MuxLiveHost.isReachable))
struct MuxLiveSmokeTests {
    @Test func detectBothAdaptersAndRecordFindings() async throws {
        let runner = MuxLiveBatchRunner()
        let tmux = TmuxAdapter(runner: runner)
        let herdr = HerdrAdapter(runner: runner)

        let tmuxResult = await liveDetect {
            try await tmux.detect()
        }
        let herdrResult = await liveDetect {
            try await herdr.detect()
        }

        try MuxLiveArtifact.write(
            "live-p39.json",
            [
                "host": MuxLiveHost.host,
                "tmux": tmuxResult,
                "herdr": herdrResult,
            ]
        )
    }
}

private func liveDetect(
    _ body: () async throws -> MultiplexerInfo
) async -> [String: Any] {
    do {
        let info = try await body()
        return [
            "present": true,
            "path": info.binaryPath,
            "version": info.version,
            "protocol": info.protocolVersion.map { $0 as Any } ?? NSNull(),
        ]
    } catch let error as ErrorState {
        return [
            "present": false,
            "error": error.stateID,
        ]
    } catch {
        return [
            "present": false,
            "error": String(describing: error),
        ]
    }
}

struct MuxLiveBatchRunner: RemoteCommandRunner {
    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        let rendered = BatchScriptBuilder().render(batch)
        let outcome = try await Task.detached {
            try MuxLiveHost.run(rendered.command)
        }.value
        return try BatchResponseParser(nonce: rendered.nonce, batch: batch)
            .parse(Data(outcome.output.utf8))
    }
}

enum MuxLiveHost {
    static var target: String { "\(setting("ANYSSH_LIVE_USER", "patricio"))@\(host)" }
    static var host: String { setting("ANYSSH_LIVE_HOST", "192.0.2.10") }

    static var isReachable: Bool {
        (try? run("true"))?.exitCode == 0
    }

    static func run(_ command: String) throws -> Outcome {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/ssh")
        process.arguments = [
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=5",
            "-o", "StrictHostKeyChecking=accept-new",
            "-i", setting("ANYSSH_LIVE_KEY", NSHomeDirectory() + "/.ssh/anyssh_dev_ed25519"),
            "-p", setting("ANYSSH_LIVE_PORT", "22"),
            target, "/bin/sh", "-s",
        ]
        let stdin = Pipe()
        let stdout = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = Pipe()
        try process.run()
        stdin.fileHandleForWriting.write(Data(command.utf8))
        try stdin.fileHandleForWriting.close()
        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return Outcome(output: String(decoding: data, as: UTF8.self), exitCode: process.terminationStatus)
    }

    struct Outcome {
        var output: String
        var exitCode: Int32
    }

    private static func setting(_ key: String, _ fallback: String) -> String {
        let value = ProcessInfo.processInfo.environment[key] ?? ""
        return value.isEmpty ? fallback : value
    }
}

enum MuxLiveArtifact {
    static func write(_ name: String, _ contents: [String: Any]) throws {
        let directory = repositoryRoot().appending(path: ".build/artifacts")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONSerialization.data(
            withJSONObject: contents,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: directory.appending(path: name), options: .atomic)
    }

    private static func repositoryRoot() -> URL {
        var url = URL(filePath: #filePath)
        for _ in 0..<5 { url = url.deletingLastPathComponent() }
        return url
    }
}
#endif
