import AnySSHCore
import FileTransfer
import Foundation
import GitClient
import Multiplexers
import Observation
import SSHTransport
import Sessions
import TerminalEmulator

@MainActor
@Observable
public final class SessionWorkspaceModel {
    public typealias SessionConnectionFactory =
        @MainActor (Remote, SessionAuthBridge?) -> any RemoteConnection
    public typealias BrowserServices = (git: any GitService, files: any RemoteFileBrowser)
    public typealias BrowserServiceFactory =
        @MainActor (any RemoteConnection, RemoteID) -> BrowserServices

    let store: TerminalSurfaceStore
    let makeConnection: SessionConnectionFactory?
    let makeBrowserServices: BrowserServiceFactory
    let secrets: (any SecretStore)?
    let hostKeys: (any HostKeyStore)?
    let signpost = SessionSwitchSignpost()
    let reconnectCoordinator: ReconnectCoordinator
    let activityCoordinator: SessionActivityCoordinator?
    let jobAlertSettings: JobAlertSettings
    let titlePreference: SessionTitlePreferenceStore
    private(set) var jobAlerts: (any NotificationScheduler)?
    #if canImport(UIKit)
    let backgroundTask = SessionBackgroundTask()
    #endif

    public internal(set) var registry: SessionRegistry
    public internal(set) var activeSessionID: SessionID?
    public internal(set) var isGridMode = false
    public internal(set) var remotes: [RemoteID: Remote]
    public internal(set) var openFailure: ErrorState?
    public internal(set) var openFailureRemoteID: RemoteID?
    public internal(set) var activeAuthBridge: SessionAuthBridge?
    public internal(set) var lastRemote: Remote?
    public internal(set) var shouldPresentSwitcher = false
    public internal(set) var barModels = [SessionID: AccessoryBarModel]()
    public internal(set) var systemNotificationRequests: [JobAlertRequest] = []
    var pendingPane: MuxPaneID?

    public let multiplexerKind: MultiplexerKind
    public let muxBindings: MuxKeyBindings?
    public let multiplexerAdapter: (any MultiplexerAdapter)?
    public let layoutDirectory: URL?
    public weak var statusToasts: StatusToastCenter?

    let lastDirectories = LastDirectoryStore.applicationSupport()

    var scopes = [SessionID: SessionActivityScope]()
    var connections = [SessionID: any RemoteConnection]()
    var authBridges = [SessionID: SessionAuthBridge]()
    var pendingSwitch: (id: SessionID, handle: SessionSwitchSignpost.Handle)?
    var sessionAdapters = [SessionID: any MultiplexerAdapter]()
    var sessionAgentKinds = [SessionID: AgentKind]()
    var sessionAgentTitles = [SessionID: String]()
    var publishedAgentTitleIDs = Set<SessionID>()
    var stallWatchers = [SessionID: Task<Void, Never>]()
    var agentStates = [SessionID: String]()

    public init(
        registry: SessionRegistry,
        remotes: [Remote],
        activeSessionID: SessionID?,
        connections: [SessionID: any RemoteConnection],
        makeEngine: @escaping TerminalSurfaceStore.EngineFactory,
        makeConnection: SessionConnectionFactory? = nil,
        secrets: (any SecretStore)? = nil,
        hostKeys: (any HostKeyStore)? = nil,
        multiplexerKind: MultiplexerKind = .none,
        muxBindings: MuxKeyBindings? = nil,
        multiplexerAdapter: (any MultiplexerAdapter)? = nil,
        layoutDirectory: URL? = nil,
        reconnectCoordinator: ReconnectCoordinator = ReconnectCoordinator(),
        activityCoordinator: SessionActivityCoordinator? = nil,
        jobAlertScheduler: (any NotificationScheduler)? = nil,
        jobAlertSettings: JobAlertSettings = JobAlertSettings(),
        titlePreference: SessionTitlePreferenceStore = .shared,
        makeBrowserServices: @escaping BrowserServiceFactory =
            SessionWorkspaceModel.remoteBrowserServices
    ) {
        store = TerminalSurfaceStore(configuration: .default, makeEngine: makeEngine)
        self.makeConnection = makeConnection
        self.makeBrowserServices = makeBrowserServices
        self.secrets = secrets
        self.hostKeys = hostKeys
        self.reconnectCoordinator = reconnectCoordinator
        self.activityCoordinator = activityCoordinator
        self.jobAlertSettings = jobAlertSettings
        self.titlePreference = titlePreference
        self.registry = registry
        self.remotes = Dictionary(uniqueKeysWithValues: remotes.map { ($0.id, $0) })
        self.activeSessionID = activeSessionID
        self.connections = connections
        self.multiplexerKind = multiplexerKind
        self.muxBindings = muxBindings
        self.multiplexerAdapter = multiplexerAdapter
        self.layoutDirectory = layoutDirectory
        if let jobAlertScheduler {
            let delivery = JobAlertDelivery(
                system: jobAlertScheduler,
                settings: jobAlertSettings,
                isForeground: JobAlertDelivery.defaultForegroundCheck,
                presentBanner: { [weak self] toast in self?.statusToasts?.present(toast) },
                onSystemRequest: { [weak self] request in
                    self?.systemNotificationRequests.append(request)
                }
            )
            jobAlerts = delivery
            store.setJobAlerts(delivery)
        }
        for record in registry.sessions {
            guard let connection = connections[record.id] else { continue }
            attach(record.id, connection: connection)
        }
    }

    public var activeRecord: SessionRecord? {
        activeSessionID.flatMap { registry[$0] }
    }

    public var activeTransportState: TransportState {
        activeRecord?.state ?? .idle
    }

    public var activeMultiplexerAdapter: (any MultiplexerAdapter)? {
        if let activeSessionID, let adapter = sessionAdapters[activeSessionID] { return adapter }
        return multiplexerAdapter
    }

    public var showsMultiplexer: Bool {
        activeMultiplexerAdapter != nil
    }

    public var activeMuxBindings: MuxKeyBindings? {
        muxBindings
    }

    public func record(for id: SessionID) -> SessionRecord? { registry[id] }
    public func surface(for id: SessionID) -> TerminalSurface? { store.surface(for: id) }
    public func scope(for id: SessionID) -> SessionActivityScope? { scopes[id] }
    public func connection(for id: SessionID) -> (any RemoteConnection)? { connections[id] }

    public static func remoteBrowserServices(
        connection: any RemoteConnection,
        remoteID: RemoteID
    ) -> BrowserServices {
        (
            RemoteGitService(runner: connection, remoteID: remoteID),
            RemoteFileBrowserService(runner: connection)
        )
    }

    func clearOpenFailure() {
        openFailure = nil
        openFailureRemoteID = nil
    }

    func recordOpenFailure(_ state: ErrorState, remoteID: RemoteID) {
        openFailure = state
        openFailureRemoteID = remoteID
    }
}

extension SessionWorkspaceModel: SessionSwitcherPresenting {
    public var canOpenAdditionalSession: Bool { activeRecord != nil }

    public func hostAddress(for id: SessionID) -> String {
        guard let record = record(for: id), let remote = remotes[record.remoteID] else {
            return record(for: id)?.title ?? "Session"
        }
        return remote.endpoint
    }

    public func remoteName(for id: SessionID) -> String? {
        record(for: id).flatMap { remotes[$0.remoteID]?.name }
    }

    public func agentKind(for id: SessionID) -> AgentKind? {
        sessionAgentKinds[id]
    }

    public func navbarTitle(mode: SessionTitleDisplayMode? = nil) -> String {
        guard let record = activeRecord else { return "Sessions" }
        let mode = mode ?? titlePreference.mode
        return SessionNavbarTitle.resolve(
            mode,
            context: SessionTitleContext(
                sessionName: record.title,
                agentSessionTitle: sessionAgentTitles[record.id],
                agentName: agentKind(for: record.id)?.name,
                multiplexerName: multiplexerName(for: record.id)
            )
        )
    }

    public func uptime(for id: SessionID) -> String {
        guard let record = record(for: id) else { return "" }
        let age = Date.now.timeIntervalSince(record.createdAt)
        guard age >= 1 else { return "just opened" }
        return Duration.seconds(age).formatted(
            .units(allowed: [.days, .hours, .minutes], width: .abbreviated)
        )
    }
}

extension SessionWorkspaceModel: SessionRestoreSource {
    public func screenDump(for id: SessionID) -> String? {
        surface(for: id)?.engine.describeScreen()
    }
}
