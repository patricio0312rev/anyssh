#if os(macOS)
import AnySSHCore
import Foundation
import Testing

@testable import AnySSHCore

@Suite(.enabled(if: RecentsLiveHost.isReachable))
struct RecentDirectoriesLiveSmokeTests {
    @Test func liveScanUsesOneRoundTripAndRecordsList() async throws {
        let counter = RecentsRoundTripCounter()
        let runner = RecentsLiveBatchRunner(counter: counter)
        let probe = SSHRecentDirectoriesProbe(runner: runner)
        let started = Date()
        let list = try await probe.list(limit: 40)
        let elapsed = Date().timeIntervalSince(started)

        #expect(counter.value == 1)
        try RecentsLiveArtifact.write(
            "live-p53.json",
            [
                "host": RecentsLiveHost.host,
                "roundTrips": counter.value,
                "elapsedSeconds": elapsed,
                "count": list.count,
                "paths": list.prefix(20).map(\.path),
                "sources": list.prefix(20).map { $0.sources.map(\.rawValue) },
            ]
        )
    }
}

final class RecentsRoundTripCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int { lock.withLock { count } }

    func record() {
        lock.withLock { count += 1 }
    }
}

struct RecentsLiveBatchRunner: RemoteCommandRunner {
    let counter: RecentsRoundTripCounter

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        let rendered = BatchScriptBuilder().render(batch)
        counter.record()
        let outcome = try RecentsLiveHost.run(rendered.command)
        return try BatchResponseParser(nonce: rendered.nonce, batch: batch)
            .parse(Data(outcome.output.utf8))
    }
}

enum RecentsLiveHost {
    static var target: String { "\(setting("ANYSSH_LIVE_USER", "dev"))@\(host)" }
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

enum RecentsLiveArtifact {
    static func write(_ name: String, _ contents: [String: Any]) throws {
        let directory = repositoryRoot().appending(path: ".build/artifacts")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONSerialization.data(
            withObject: contents,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: directory.appending(path: name), options: .atomic)
    }

    private static func repositoryRoot() -> URL {
        var url = URL(filePath: #filePath)
        for _ in 0..<6 { url = url.deletingLastPathComponent() }
        return url
    }
}

extension JSONSerialization {
    fileprivate static func data(
        withObject object: [String: Any],
        options: WritingOptions
    ) throws -> Data {
        try data(withJSONObject: object, options: options)
    }
}
#endif
