import AnySSHCore
import AnySSHUI
import Highlighting
import SwiftUI

struct RootView: View {
    let environment: AppEnvironment

    @State private var routed: LaunchScenario?

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
        .background {
            launchDiagnostics
        }
    }

    @ViewBuilder
    private var screen: some View {
        if let migrationFailure = environment.migrationFailure {
            ErrorStateView(state: .secrets(migrationFailure))
        } else if environment.isMock {
            switch routed ?? environment.scenario {
            case .remotes:
                remotes
            case .remoteForm(let route):
                RemoteFormScenarioView(environment: environment, route: route)
            case .hostKeyTrust:
                TrustScenarioView(store: environment.hostKeyStore, scenario: environment.scenario)
            case .authPrompt:
                AuthPromptScenarioView()
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
            }
        } else {
            remotes
        }
    }

    private var remotes: some View {
        RemotesListView(
            store: environment.remoteStore,
            secrets: environment.secretStore,
            hostKeys: environment.hostKeyStore,
            probe: environment.reachabilityProbe
        )
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
