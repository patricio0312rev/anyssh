import AnySSHCore
import Foundation

public struct ScriptedReachability: ReachabilityProbe {
    public enum Script: Sendable, Equatable {
        case reachable
        case unreachable
        case unknown
        case slow(Reachability, Duration)
    }

    public let script: Script
    public let byRemote: [RemoteID: Script]

    public init(_ script: Script) {
        self.script = script
        self.byRemote = [:]
    }

    public init(byRemote: [RemoteID: Script], default script: Script = .unknown) {
        self.script = script
        self.byRemote = byRemote
    }

    public func probe(_ remote: Remote) async -> Reachability {
        await resolve(byRemote[remote.id] ?? script)
    }

    private func resolve(_ script: Script) async -> Reachability {
        switch script {
        case .reachable:
            return .reachable
        case .unreachable:
            return .unreachable
        case .unknown:
            return .unknown
        case .slow(let result, let delay):
            try? await Task.sleep(for: delay)
            return result
        }
    }
}

extension ScriptedReachability.Script {
    public var presentation: ReachabilityPresentation {
        switch self {
        case .reachable: .reachable
        case .unreachable: .unreachable
        case .unknown: .unknown
        case .slow: .checking
        }
    }
}
