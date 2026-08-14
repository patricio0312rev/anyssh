import AnySSHCore
import Foundation
import SSHTransport

public enum ConnectionTestOutcome: Equatable, Sendable {
    case authenticated
    case unreachable(ErrorState)
    case authenticationFailed(ErrorState)
}

public enum ConnectionTest {
    public static func run(
        remote: Remote,
        secrets: any SecretStore,
        hostKeys: any HostKeyStore,
        passwordOverride: String?,
        answering: AuthPromptAnswering?,
        delegate: any TerminalTransportDelegate,
        probe: any ReachabilityProbe = NWConnectionProbe()
    ) async -> ConnectionTestOutcome {
        let reachability = await probe.probe(remote)
        guard reachability == .reachable else {
            return .unreachable(.transport(.hostUnreachable))
        }

        let connection = ConnectionFactory.make(
            remote: remote,
            secrets: secrets,
            hostKeys: hostKeys,
            connectionID: ConnectionID(rawValue: "test.\(UUID().uuidString.prefix(8))"),
            passwordOverride: passwordOverride,
            answering: answering
        )
        await connection.setDisplayDelegate(delegate)
        let sink = DiscardingByteSink()
        do {
            try await connection.attachDisplay(sink: sink, size: .standard)
            await connection.close(reason: .closedByUser)
            return .authenticated
        } catch let error as any UserFacingError {
            await connection.close(reason: .closedByUser)
            let state = ErrorState(stateID: error.stateID) ?? .auth(.passwordRejected)
            if state.stateID.hasPrefix("auth.") || state.stateID.hasPrefix("trust.") {
                return .authenticationFailed(state)
            }
            return .unreachable(state)
        } catch {
            await connection.close(reason: .closedByUser)
            return .unreachable(.transport(.connectionRefused))
        }
    }
}

private actor DiscardingByteSink: ByteSink {
    func ingest(_ bytes: ArraySlice<UInt8>) async {
        _ = bytes
    }
}
