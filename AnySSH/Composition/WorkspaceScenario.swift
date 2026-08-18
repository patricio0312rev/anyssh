import AnySSHMocks
import AnySSHUI

enum WorkspaceScenario: String, Equatable, CaseIterable {
    case four = "sessions.workspace"
    case single = "sessions.workspace.single"
    case empty = "sessions.workspace.empty"
    case tmux = "sessions.workspace.tmux"
    case herdr = "sessions.workspace.herdr"
    case agent = "sessions.workspace.agent"
    case accessory = "sessions.workspace.accessory"
    case compact = "sessions.workspace.compact"
    case landscape = "sessions.workspace.landscape"
    case switcher = "sessions.workspace.switcher"
    case palette = "sessions.workspace.palette"
    case changes = "sessions.workspace.changes"
    case files = "sessions.workspace.files"
    case reconnect = "sessions.workspace.reconnect"
    case jobAlerts = "sessions.jobAlerts"
    case notifyForeground = "sessions.notifyForeground"
    case notifyBackground = "sessions.notifyBackground"
    case opened = "sessions.opened"
    case openedBrowser = "sessions.opened.browser"
    case terminal = "terminal.workspace"
    case restore = "sessions.restore"

    var recordsFixture: String {
        switch self {
        case .single, .agent, .accessory, .compact: "single"
        case .empty: "empty"
        case .notifyForeground: "notifyForeground"
        case .notifyBackground: "notifyBackground"
        default: "four"
        }
    }

    var surface: WorkspaceSurface? {
        switch self {
        case .switcher: .switcher
        case .palette: .palette
        case .changes, .openedBrowser, .landscape: .changes
        case .files: .files
        case .jobAlerts: .jobAlerts
        default: nil
        }
    }

    var alertScript: MockDisplayScript {
        switch self {
        case .notifyForeground:
            MockDisplayScript(steps: [
                MockDisplayStep(delay: .seconds(1), bytes: Array(Self.osc9Alert.utf8))
            ])
        case .notifyBackground:
            MockDisplayScript(steps: [
                MockDisplayStep(delay: .seconds(6), bytes: Array(Self.osc9Alert.utf8))
            ])
        default:
            MockDisplayScript()
        }
    }

    var deliversAlerts: Bool {
        self == .notifyForeground || self == .notifyBackground
    }

    private static let osc9Alert = "\u{1b}]9;Backup finished\u{7}"

    var isMultiplexed: Bool {
        self == .tmux || self == .herdr
    }

    var fitsTranscriptToGrid: Bool {
        self == .agent
    }

    func transcript(columns: Int, rows: Int) -> [UInt8] {
        switch self {
        case .agent: OpenCodeHomeTranscript.home(columns: columns, rows: rows)
        case .tmux, .herdr: Array(WorkspaceScenarioTranscript.multiplexed.utf8)
        default: Array(WorkspaceScenarioTranscript.shell.utf8)
        }
    }

    var forcesAccessoryBar: Bool {
        self == .accessory
    }

    var prefersLandscape: Bool {
        self == .landscape
    }

    var opensFromRemotes: Bool {
        self == .opened || self == .openedBrowser
    }
}
