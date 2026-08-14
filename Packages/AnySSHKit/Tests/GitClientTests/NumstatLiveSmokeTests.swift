import AnySSHCore
import Foundation
import Testing

@testable import GitClient

@Suite struct GitLiveSmokeTests {
    private struct Repo {
        let path: String

        init() throws {
            path = NSTemporaryDirectory() + "anyssh-git-" + UUID().uuidString
            try FileManager.default.createDirectory(
                atPath: path, withIntermediateDirectories: true
            )
            try run(["init", "-q", "-b", "main"])
            try run(["config", "user.email", "test@example.com"])
            try run(["config", "user.name", "Test"])
            try write("tracked.swift", lines: (1...20).map { "let line\($0) = \($0)" })
            try run(["add", "."])
            try run(["commit", "-qm", "first"])
            try write(
                "tracked.swift",
                lines: (1...20).map { $0 <= 10 ? "let changed\($0) = \($0 * 2)" : "let line\($0) = \($0)" }
            )
        }

        func write(_ name: String, lines: [String]) throws {
            try (lines.joined(separator: "\n") + "\n")
                .write(toFile: path + "/" + name, atomically: true, encoding: .utf8)
        }

        @discardableResult
        func run(_ arguments: [String]) throws -> Data {
            let process = Process()
            process.executableURL = URL(filePath: "/usr/bin/env")
            process.arguments = ["git", "-C", path] + arguments
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return data
        }

        func remove() {
            try? FileManager.default.removeItem(atPath: path)
        }
    }

    @Test func theCountsReachTheStatusFiles() throws {
        let repo = try Repo()
        defer { repo.remove() }

        let status = try StatusParser().parse(
            try repo.run(["status", "--porcelain=v2", "-z", "--branch", "--untracked-files=all", "--renames"])
        )
        let counts = try NumstatParser().parse(try repo.run(["diff", "--numstat", "-z", "-M"]))
        let merged = NumstatMerge.apply(counts, to: status.unstaged)

        #expect(merged.count == 1)
        #expect(merged.first?.additions == 10)
        #expect(merged.first?.deletions == 10)
    }

    @Test func aRealPatchParses() throws {
        let repo = try Repo()
        defer { repo.remove() }

        let file = ChangedFile(
            oldPath: nil, newPath: "tracked.swift", change: .modified, isBinary: false
        )
        let patch = try repo.run(["diff", "-M", "--no-ext-diff", "--no-textconv", "--"] + file.pathspec)
        let diff = try DiffParser().parse(patch, file: file)

        #expect(!diff.hunks.isEmpty)
        #expect(!diff.truncated)
        #expect(diff.hunks.flatMap(\.lines).filter { $0.kind == .addition }.count == 10)
    }

    @Test func anUntrackedFileDiffsAgainstNothing() throws {
        let repo = try Repo()
        defer { repo.remove() }
        try repo.write("brand-new.swift", lines: (1...4).map { "let new\($0) = \($0)" })

        let patch = try repo.run(["diff", "--no-index", "-M", "--", "/dev/null", "brand-new.swift"])
        let file = ChangedFile(
            oldPath: nil, newPath: "brand-new.swift", change: .added, isBinary: false
        )
        let diff = try DiffParser().parse(patch, file: file)

        #expect(diff.hunks.flatMap(\.lines).filter { $0.kind == .addition }.count == 4)
    }
}
