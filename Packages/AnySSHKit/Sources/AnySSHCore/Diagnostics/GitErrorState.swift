public enum GitErrorState: String, ErrorStateMember {
    case missing
    case notARepository
    case unbornBranch
    case detachedHead
    case noUpstream
    case mergeInProgress
    case renameLimit
    case diffTruncated
    case combinedDiffUnsupported
    case submoduleEntry
    case binaryDiff
    case modeOnlyChange

    public static let group = ErrorStateGroup.git

    public var copy: ErrorStateCopy {
        switch self {
        case .missing:
            ErrorStateCopy(
                title: "Git not found",
                body: "The host has no git on its login shell PATH. Install it, or add it to "
                    + "that PATH.",
                recoveryLabel: "Check Again"
            )
        case .notARepository:
            ErrorStateCopy(
                title: "Not a git repository",
                body: "The session's directory is not inside a git working tree. "
                    + "Move to one and check again.",
                recoveryLabel: "Check Again"
            )
        case .unbornBranch:
            ErrorStateCopy(
                title: "No commits yet",
                body: "This repository has no commits, so there is nothing to compare against. "
                    + "Every file reads as new.",
                recoveryLabel: "View Files"
            )
        case .detachedHead:
            ErrorStateCopy(
                title: "Detached HEAD",
                body: "This repository sits on a commit rather than a branch, so there is no "
                    + "upstream to compare with.",
                recoveryLabel: "View History"
            )
        case .noUpstream:
            ErrorStateCopy(
                title: "No upstream branch",
                body: "This branch tracks nothing, so ahead and behind counts are unavailable. "
                    + "Set an upstream on the host.",
                recoveryLabel: "Dismiss"
            )
        case .mergeInProgress:
            ErrorStateCopy(
                title: "Merge in progress",
                body: "This repository is mid-merge. Conflicted files show both sides; finish "
                    + "or abort the merge on the host.",
                recoveryLabel: "View Conflicts"
            )
        case .renameLimit:
            ErrorStateCopy(
                title: "Renames not detected",
                body: "The change set is past git's rename limit, so renames read as a delete "
                    + "and an add. Raise diff.renameLimit on the host.",
                recoveryLabel: "Dismiss"
            )
        case .diffTruncated:
            ErrorStateCopy(
                title: "Diff truncated",
                body: "This diff passed 256 KB and was cut off there. Open the file to read the "
                    + "rest.",
                recoveryLabel: "Open File"
            )
        case .combinedDiffUnsupported:
            ErrorStateCopy(
                title: "Merge diff not shown",
                body: "This commit has more than one parent, and combined diffs are not "
                    + "rendered. Open a parent to see its changes.",
                recoveryLabel: "Choose Parent"
            )
        case .submoduleEntry:
            ErrorStateCopy(
                title: "Submodule",
                body: "This entry records a commit in another repository rather than file "
                    + "content.",
                recoveryLabel: "Dismiss"
            )
        case .binaryDiff:
            ErrorStateCopy(
                title: "Binary file",
                body: "Git can report that this file changed, but it cannot show its contents as "
                    + "text.",
                recoveryLabel: "Dismiss"
            )
        case .modeOnlyChange:
            ErrorStateCopy(
                title: "File mode changed",
                body: "Only this file's executable permission changed. There is no text diff to "
                    + "show.",
                recoveryLabel: "Dismiss"
            )
        }
    }

    public var owningPhase: Int {
        switch self {
        case .missing: 28
        case .notARepository, .unbornBranch, .detachedHead, .noUpstream, .mergeInProgress: 33
        case .renameLimit, .diffTruncated, .combinedDiffUnsupported, .submoduleEntry,
            .binaryDiff, .modeOnlyChange:
            37
        }
    }
}
