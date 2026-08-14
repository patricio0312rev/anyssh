enum GitScenario: String, Equatable, CaseIterable {
    case changes = "git.changes"
    case changesExpanded = "git.changes.expanded"
    case changesClean = "git.changes.clean"
    case history = "git.history"
    case historyEmpty = "git.history.empty"
    case historyDetail = "git.history.detail"
    case diff = "git.diff"
}
