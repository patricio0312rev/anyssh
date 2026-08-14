import AnySSHCore

public enum GitCommand: Hashable, Sendable {
    case repositoryRoot
    case gitDirectory
    case status
    case unstagedNumstat
    case stagedNumstat
    case log(limit: Int, skip: Int)
    case logBefore(limit: Int, commit: CommitID)
    case perFileDiff(pathspec: [String], staged: Bool)
    case untrackedDiff(path: String)
    case blob(oid: String)
    case commitPatch(oid: String)
    case batchCheck

    public var invocation: GitInvocation {
        GitInvocation(
            arguments: [GitInvocation.executable] + GitInvocation.globalArguments + tail,
            minimumGitVersion: minimumGitVersion
        )
    }

    public var minimumGitVersion: String {
        switch self {
        case .repositoryRoot: "1.7.0"
        case .gitDirectory: "1.5.0"
        case .status: "2.18.0"
        case .unstagedNumstat, .stagedNumstat, .log, .logBefore, .perFileDiff, .commitPatch,
            .untrackedDiff:
            "1.7.0"
        case .blob: "1.5.0"
        case .batchCheck: "2.36.0"
        }
    }

    private var tail: [String] {
        switch self {
        case .repositoryRoot:
            ["rev-parse", "--show-toplevel"]
        case .gitDirectory:
            ["rev-parse", "--git-dir"]
        case .status:
            ["status", "--porcelain=v2", "-z", "--branch", "--untracked-files=all", "--renames"]
        case .unstagedNumstat:
            ["diff", "--numstat", "-z", "-M"] + GitInvocation.diffFlags
        case .stagedNumstat:
            ["diff", "--cached", "--numstat", "-z", "-M"] + GitInvocation.diffFlags
        case .log(let limit, let skip):
            [
                "log", "-z", "--format=" + Self.logFormat, "--max-count=" + String(limit),
                "--skip=" + String(skip),
            ] + GitInvocation.diffFlags
        case .logBefore(let limit, let commit):
            [
                "log", "-z", "--format=" + Self.logFormat, "--max-count=" + String(limit), "--no-decorate",
                commit.rawValue + "^",
            ] + GitInvocation.diffFlags
        case .untrackedDiff(let path):
            ["diff", "--no-index", "-M"] + GitInvocation.diffFlags + ["--", "/dev/null", path]
        case .perFileDiff(let pathspec, let staged):
            ["diff"] + (staged ? ["--cached"] : []) + ["-M"] + GitInvocation.diffFlags
                + ["--"] + pathspec
        case .blob(let oid):
            ["cat-file", "blob", oid]
        case .commitPatch(let oid):
            ["show", "--format=", "--patch", "-M", "-m", "--first-parent"]
                + GitInvocation.diffFlags + [oid]
        case .batchCheck:
            ["cat-file", "--batch-check", "-Z"]
        }
    }

    private static let logFormat =
        "\u{1}%H%x00%h%x00%P%x00%an%x00%ae%x00%aI%x00%ar%x00%cI%x00%D%x00%s%x00%b"
}
