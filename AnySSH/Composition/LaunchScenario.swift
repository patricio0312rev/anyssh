import AnySSHCore
import AnySSHMocks

enum LaunchScenario: Equatable {
    case remotes(String)
    case hostKeyTrust(String)
    case authPrompt
    case errorState(ErrorState)

    static let fallback = LaunchScenario.remotes("default")

    static let remoteFixtures = ["default", "empty", "single", "many", "mixed"]
    static let authPromptName = "auth.keyboardInteractive"

    init(_ name: String) {
        if name.isEmpty || Self.remoteFixtures.contains(name) {
            self = .remotes(name.isEmpty ? "default" : name)
        } else if HostKeyFixtures.scenarios[name] != nil {
            self = .hostKeyTrust(name)
        } else if name == Self.authPromptName {
            self = .authPrompt
        } else if let state = ErrorState(stateID: Self.stateID(from: name)) {
            self = .errorState(state)
        } else {
            self = Self.fallback
        }
    }

    private static func stateID(from name: String) -> String {
        name.hasPrefix("error.") ? String(name.dropFirst("error.".count)) : name
    }

    var remotesFixture: String {
        switch self {
        case .remotes(let name): name
        case .hostKeyTrust, .authPrompt, .errorState: "single"
        }
    }

    var hostKeyScenario: ScriptedHostKeyStore.Scenario {
        guard case .hostKeyTrust(let name) = self else { return .unknownHost }
        return HostKeyFixtures.scenarios[name] ?? .unknownHost
    }

    var secretFailure: InMemorySecretStore.Failure? {
        guard case .errorState(.secrets(let state)) = self else { return nil }
        return InMemorySecretStore.Failure.allCases.first { $0.error.state == state }
    }
}
