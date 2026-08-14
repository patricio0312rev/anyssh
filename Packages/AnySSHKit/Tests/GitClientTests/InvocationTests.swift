import AnySSHCore
import Testing

@testable import GitClient

@Suite struct InvocationTests {
    private static let hardenedPrefix = [
        "git", "--no-pager",
        "-c", "core.quotePath=false",
        "-c", "color.ui=false",
        "-c", "diff.renames=true",
        "-c", "log.showSignature=false",
    ]
    private static let diffFlags = ["--no-ext-diff", "--no-textconv", "--src-prefix=a/", "--dst-prefix=b/"]

    @Test func repositoryRootRendersTheHardenedArgv() {
        let invocation = GitCommand.repositoryRoot.invocation
        #expect(invocation.arguments == Self.hardenedPrefix + ["rev-parse", "--show-toplevel"])
        #expect(invocation.minimumGitVersion == "1.7.0")
    }

    @Test func gitDirectoryRendersTheHardenedArgv() {
        let invocation = GitCommand.gitDirectory.invocation
        #expect(invocation.arguments == Self.hardenedPrefix + ["rev-parse", "--git-dir"])
        #expect(invocation.minimumGitVersion == "1.5.0")
    }

    @Test func statusRendersTheHardenedArgv() {
        let invocation = GitCommand.status.invocation
        #expect(
            invocation.arguments == Self.hardenedPrefix
                + ["status", "--porcelain=v2", "-z", "--branch", "--untracked-files=all", "--renames"]
        )
        #expect(invocation.minimumGitVersion == "2.18.0")
    }

    @Test func unstagedNumstatRendersTheHardenedArgv() {
        let invocation = GitCommand.unstagedNumstat.invocation
        #expect(
            invocation.arguments == Self.hardenedPrefix + ["diff", "--numstat", "-z", "-M"] + Self.diffFlags
        )
        #expect(invocation.minimumGitVersion == "1.7.0")
    }

    @Test func stagedNumstatRendersTheHardenedArgv() {
        let invocation = GitCommand.stagedNumstat.invocation
        #expect(
            invocation.arguments == Self.hardenedPrefix
                + ["diff", "--cached", "--numstat", "-z", "-M"] + Self.diffFlags
        )
        #expect(invocation.minimumGitVersion == "1.7.0")
    }

    @Test func logRendersTheHardenedArgv() {
        let invocation = GitCommand.log(limit: 50, skip: 25).invocation
        let format = "--format=\u{1}%H%x00%h%x00%P%x00%an%x00%ae%x00%aI%x00%ar%x00%cI%x00%D%x00%s%x00%b"
        #expect(
            invocation.arguments == Self.hardenedPrefix
                + ["log", "-z", format, "--max-count=50", "--skip=25"] + Self.diffFlags
        )
        #expect(invocation.minimumGitVersion == "1.7.0")
    }

    @Test func perFileDiffAppendsThePathspecAfterTheSeparator() {
        let invocation = GitCommand.perFileDiff(
            pathspec: ["Sources/MetricsRenderer.swift", "Sources/LegacyRenderer.swift"],
            staged: true
        ).invocation
        #expect(
            invocation.arguments == Self.hardenedPrefix
                + ["diff", "--cached", "-M"] + Self.diffFlags
                + ["--", "Sources/MetricsRenderer.swift", "Sources/LegacyRenderer.swift"]
        )
        #expect(invocation.minimumGitVersion == "1.7.0")
    }

    @Test func blobRendersTheHardenedArgv() {
        let invocation = GitCommand.blob(oid: "92f0830").invocation
        #expect(invocation.arguments == Self.hardenedPrefix + ["cat-file", "blob", "92f0830"])
        #expect(invocation.minimumGitVersion == "1.5.0")
    }

    @Test func commitPatchRendersTheHardenedArgv() {
        let invocation = GitCommand.commitPatch(oid: "92f0830").invocation
        #expect(
            invocation.arguments == Self.hardenedPrefix
                + ["show", "--format=", "--patch", "-M", "-m", "--first-parent"] + Self.diffFlags
                + ["92f0830"]
        )
        #expect(invocation.minimumGitVersion == "1.7.0")
    }

    @Test func batchCheckRendersTheHardenedArgv() {
        let invocation = GitCommand.batchCheck.invocation
        #expect(invocation.arguments == Self.hardenedPrefix + ["cat-file", "--batch-check", "-Z"])
        #expect(invocation.minimumGitVersion == "2.36.0")
    }

    @Test func diffFamilyCommandsCarryNoExtDiff() {
        let commands: [GitCommand] = [
            .unstagedNumstat, .stagedNumstat, .log(limit: 1, skip: 0),
            .perFileDiff(pathspec: ["a"], staged: false), .commitPatch(oid: "a"),
        ]
        for command in commands {
            #expect(command.invocation.arguments.contains("--no-ext-diff"))
        }
    }

    @Test func statusAndRevParseCommandsRejectTheDiffFlags() {
        let commands: [GitCommand] = [.repositoryRoot, .gitDirectory, .status]
        for command in commands {
            #expect(!command.invocation.arguments.contains("--no-ext-diff"))
        }
    }

    @Test func pathspecNamesBothSidesOfARename() {
        let renamed = ChangedFile(
            oldPath: "Sources/LegacyRenderer.swift",
            newPath: "Sources/MetricsRenderer.swift",
            change: .renamed(similarity: 100),
            isBinary: false
        )
        #expect(renamed.pathspec == ["Sources/MetricsRenderer.swift", "Sources/LegacyRenderer.swift"])
    }

    @Test func pathspecNamesOnePathForAModification() {
        let modified = ChangedFile(
            oldPath: nil, newPath: "Sources/API.swift", change: .modified, isBinary: false)
        #expect(modified.pathspec == ["Sources/API.swift"])
    }

    @Test func pathspecNamesTheOldPathForADeletion() {
        let deleted = ChangedFile(
            oldPath: "Sources/API.swift", newPath: nil, change: .deleted, isBinary: false)
        #expect(deleted.pathspec == ["Sources/API.swift"])
    }
}
