import AnySSHCore
import Foundation

@testable import SSHTransport

enum CommandRunnerFixture {
    static let sixCommandBatch = RemoteBatch(commands: [
        RemoteCommand(label: "ok.true", arguments: ["true"]),
        RemoteCommand(label: "ok.printf", arguments: ["printf", "%s", "ready"]),
        RemoteCommand(label: "fail.false", arguments: ["false"]),
        RemoteCommand(label: "ok.id", arguments: ["printf", "%s", "next"]),
        RemoteCommand(label: "missing", arguments: ["anyssh-definitely-not-a-program"]),
        RemoteCommand(label: "capped", arguments: ["/bin/cat", "/dev/zero"], byteCap: 64),
    ])

    static let expectedExitCodes: [Int32] = [0, 0, 1, 0, 127, 141]

    static func runner(
        idleTTL: Duration = ConnectionProfile.defaultControlIdleTTL,
        queueTimeout: Duration = ControlChannelGate.defaultQueueTimeout
    ) async throws -> (runner: SSHCommandRunner, connection: SSHRemoteConnection) {
        let (connection, _) = try await ConnectionTestbed.opened(idleTTL: idleTTL)
        let runner = SSHCommandRunner(connection: connection, queueTimeout: queueTimeout)
        return (runner, connection)
    }

    static func liveRunner() async throws -> (
        runner: SSHCommandRunner,
        connection: SSHRemoteConnection
    ) {
        let host = LiveHost.development
        let sink = ShellSink()
        let connection = SSHRemoteConnection(
            profile: ConnectionProfile(
                connectionID: ConnectionID(rawValue: "live-p29"),
                target: SessionTarget(host: host.host, port: Int(host.port)),
                username: host.username,
                display: DisplayTransportConfiguration(session: AuthSupport.patient),
                control: AuthSupport.patient
            ),
            credentials: ConnectionCredentials(
                .privateKey(AuthSupport.key(host.privateKeyPath))
            ),
            hostKeys: MemoryHostKeyStore()
        )
        await connection.setDisplaySink(sink)
        await connection.setDisplayDelegate(DisplayDelegate())
        try await connection.startDisplay(size: TerminalSize(columns: 80, rows: 24))
        return (SSHCommandRunner(connection: connection), connection)
    }

    static func stateID(of error: any Error) -> String {
        (error as? any UserFacingError)?.stateID ?? "test.unexpectedError"
    }

    static func stateID<Value>(of task: Task<Value, any Error>) async -> String? {
        do {
            _ = try await task.value
            return nil
        } catch {
            return stateID(of: error)
        }
    }
}
