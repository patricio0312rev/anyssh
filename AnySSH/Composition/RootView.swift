import AnySSHCore
import AnySSHUI
import Highlighting
import SwiftUI

struct RootView: View {
    let environment: AppEnvironment

    @State private var routed: LaunchScenario?
    @State private var sessions: SessionController
    @State private var restoredWorkspace: SessionWorkspaceModel?
    @Environment(\.scenePhase) private var scenePhase

    init(environment: AppEnvironment) {
        self.environment = environment
        _sessions = State(
            wrappedValue: SessionController(
                secrets: environment.secretStore,
                hostKeys: environment.hostKeyStore,
                isMock: environment.isMock,
                restoreStore: environment.sessionRestoreStore,
                restoreEnabled: environment.restoreEnabled,
                activityPresenter: LiveActivityPresenter()
            )
        )
    }

    var body: some View {
        ThemedRoot {
            screen
        }
        .environment(\.fileIconImageProvider, BundleFileIconImageProvider())
        .environment(\.syntaxHighlighter, TreeSitterHighlighter())
        .onOpenURL { url in
            guard environment.isMock else { return }
            routed = DeepLinkRouter.scenario(for: url) ?? routed
        }
        .task {
            let remotes = (try? await environment.remoteStore.remotes()) ?? []
            restoredWorkspace = sessions.restoredWorkspace(remotes: remotes)
        }
        .onChange(of: scenePhase) { _, phase in
            Task { await sessions.activityPhaseChanged(phase) }
        }
        .background {
            launchDiagnostics
        }
    }

    @ViewBuilder
    private var screen: some View {
        if let migrationFailure = environment.migrationFailure {
            ErrorStateView(state: .secrets(migrationFailure))
        } else if let model = restoredWorkspace {
            SessionWorkspaceView(model: model) {
                sessions.leaveWorkspace()
                restoredWorkspace = nil
            }
            .sessionRestoreLifecycle(model: model, coordinator: sessions.restoreCoordinator)
        } else if environment.isMock {
            scenarioScreen
        } else {
            remotes
        }
    }

    @ViewBuilder
    private var scenarioScreen: some View {
        switch routed ?? environment.scenario {
        case .remotes:
            remotes
        case .remoteForm(let route):
            RemoteFormScenarioView(environment: environment, route: route)
        case .hostKeyTrust:
            TrustScenarioView(store: environment.hostKeyStore, scenario: environment.scenario)
        case .authPrompt:
            AuthPromptScenarioView()
        case .savePassword:
            AuthSavePasswordScenarioView()
        case .errorState(let state):
            ErrorStateScenarioView(state: state, secrets: environment.secretStore)
        case .terminal(let scenario):
            TerminalScenarioView(scenario: scenario)
        case .git(let scenario):
            GitScenarioView(scenario: scenario)
        case .files(let scenario):
            FilesScenarioView(scenario: scenario)
        case .sessions(let scenario):
            SessionsScenarioView(scenario: scenario)
        case .workspace(let scenario):
            workspaceScenario(scenario)
        }
    }

    @ViewBuilder
    private func workspaceScenario(_ scenario: WorkspaceScenario) -> some View {
        if scenario.opensFromRemotes {
            remotes(coverSurface: scenario.surface)
                .task { await openFirstRemote() }
        } else {
            sessions.scenarioWorkspace(scenario)
        }
    }

    private func openFirstRemote() async {
        guard let remote = try? await environment.remoteStore.remotes().first else { return }
        await sessions.open(remote)
    }

    private var remotes: some View {
        remotes(coverSurface: nil)
    }

    private func remotes(coverSurface: WorkspaceSurface?) -> some View {
        @Bindable var sessions = sessions
        return RemotesListView(
            store: environment.remoteStore,
            secrets: environment.secretStore,
            hostKeys: environment.hostKeyStore,
            probe: environment.reachabilityProbe,
            onOpen: { remote in
                Task { await sessions.open(remote) }
            }
        )
        .fullScreenCover(isPresented: $sessions.isPresentingWorkspace) {
            if let model = sessions.workspace {
                SessionWorkspaceView(
                    model: model,
                    initialSurface: coverSurface,
                    hostsToasts: true
                ) {
                    sessions.leaveWorkspace()
                }
                .sessionRestoreLifecycle(model: model, coordinator: sessions.restoreCoordinator)
            }
        }
    }

    private var launchDiagnostics: some View {
        Text(String(environment.keychainMigrationRuns))
            .font(Theme.Text.caption)
            .frame(width: 1, height: 1)
            .clipped()
            .opacity(0)
            .accessibilityIdentifier(UIIdentifier.Launch.keychainMigrationRuns)
    }
}
