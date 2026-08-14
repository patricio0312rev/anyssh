import AnySSHUI

enum WorkspaceScenario: String, Equatable, CaseIterable {
    case four = "sessions.workspace"
    case single = "sessions.workspace.single"
    case empty = "sessions.workspace.empty"
    case tmux = "sessions.workspace.tmux"
    case herdr = "sessions.workspace.herdr"
    case switcher = "sessions.workspace.switcher"
    case palette = "sessions.workspace.palette"
    case changes = "sessions.workspace.changes"
    case files = "sessions.workspace.files"
    case reconnect = "sessions.workspace.reconnect"
    case opened = "sessions.opened"
    case openedBrowser = "sessions.opened.browser"
    case terminal = "terminal.workspace"
    case restore = "sessions.restore"

    var recordsFixture: String {
        switch self {
        case .single: "single"
        case .empty: "empty"
        default: "four"
        }
    }

    var surface: WorkspaceSurface? {
        switch self {
        case .switcher: .switcher
        case .palette: .palette
        case .changes, .openedBrowser: .changes
        case .files: .files
        default: nil
        }
    }

    var isMultiplexed: Bool {
        self == .tmux || self == .herdr
    }

    var opensFromRemotes: Bool {
        self == .opened || self == .openedBrowser
    }
}
