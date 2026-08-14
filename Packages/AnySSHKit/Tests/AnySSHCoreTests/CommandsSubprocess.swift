#if os(macOS)
import Foundation

enum CommandsSubprocess {
    struct Outcome: Sendable {
        let stdout: Data
        let exitCode: Int32
    }

    static func run(
        _ executable: String,
        _ arguments: [String] = [],
        stdin: Data = Data(),
        overrides: [String: String] = [:],
        removing: [String] = []
    ) throws -> Outcome {
        let process = Process()
        process.executableURL = URL(filePath: executable)
        process.arguments = arguments
        process.environment = environment(overrides, removing)
        let output = Pipe()
        let input = Pipe()
        process.standardOutput = output
        process.standardInput = input
        process.standardError = FileHandle.nullDevice
        try process.run()
        try input.fileHandleForWriting.write(contentsOf: stdin)
        try input.fileHandleForWriting.close()
        let stdout = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return Outcome(stdout: stdout, exitCode: process.terminationStatus)
    }

    static func sh(_ command: String, overrides: [String: String] = [:], removing: [String] = [])
        throws -> Outcome
    {
        try run(
            "/bin/sh",
            stdin: Data(command.utf8),
            overrides: overrides,
            removing: removing
        )
    }

    static let quietZshEnvironment: [String: String] = {
        let directory = FileManager.default.temporaryDirectory.appending(path: "anyssh-quiet-zdotdir")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return ["SHELL": "/bin/zsh", "ZDOTDIR": directory.path(percentEncoded: false)]
    }()

    private static func environment(_ overrides: [String: String], _ removing: [String])
        -> [String: String]
    {
        var environment = ProcessInfo.processInfo.environment
        for key in removing { environment.removeValue(forKey: key) }
        return environment.merging(overrides) { _, override in override }
    }
}
#endif
