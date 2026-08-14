import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

enum ConnectionTestbed {
    static func connection(
        idleTTL: Duration = ConnectionProfile.defaultControlIdleTTL,
        user: String = "keyuser",
        credentials: ConnectionCredentials? = nil
    ) -> SSHRemoteConnection {
        let testbed = AuthEnvironment.testbed
        let profile = ConnectionProfile(
            connectionID: ConnectionID(rawValue: UUID().uuidString),
            target: SessionTarget(
                host: testbed?.host ?? TestbedHost.sshd.host,
                port: testbed?.port ?? Int(TestbedHost.sshd.port)
            ),
            username: user,
            display: DisplayTransportConfiguration(session: AuthSupport.patient),
            control: AuthSupport.patient,
            controlIdleTTL: idleTTL
        )
        return SSHRemoteConnection(
            profile: profile,
            credentials: credentials
                ?? ConnectionCredentials(.privateKey(AuthSupport.key(AuthEnvironment.ed25519))),
            hostKeys: MemoryHostKeyStore()
        )
    }

    static func opened(idleTTL: Duration = ConnectionProfile.defaultControlIdleTTL) async throws
        -> (connection: SSHRemoteConnection, sink: ShellSink)
    {
        try await LiveSetupRetry.run {
            let sink = ShellSink()
            let connection = connection(idleTTL: idleTTL)
            await connection.setDisplaySink(sink)
            await connection.setDisplayDelegate(DisplayDelegate())
            try await connection.startDisplay(size: TerminalSize(columns: 80, rows: 24))
            return (connection, sink)
        }
    }

    static func identities(
        _ connection: SSHRemoteConnection
    ) async -> (display: SessionIdentity?, control: SessionIdentity?) {
        var display: SessionIdentity?
        var control: SessionIdentity?
        if let transport = await connection.display, let session = await transport.session {
            display = await session.identity
        }
        if let transport = await connection.control {
            control = await transport.identity
        }
        return (display, control)
    }

    static func batch(_ label: String, _ arguments: [String]) -> RemoteBatch {
        RemoteBatch(commands: [RemoteCommand(label: label, arguments: arguments)])
    }

    static func sleeping(_ label: String, seconds: Int = 10) -> RemoteBatch {
        batch(label, ["sleep", "\(seconds)"])
    }

    static func blocking(_ label: String) -> RemoteBatch {
        batch(label, ["cat"])
    }

    static func text(_ response: BatchResponse, _ label: String) -> String {
        guard let section = response.sections.first(where: { $0.label == label }) else { return "" }
        return String(decoding: section.bytes, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func reportedClientPort(_ text: String) -> Int? {
        let fields = text.split(separator: " ")
        guard fields.count >= 2 else { return nil }
        return Int(fields[1])
    }

    static let clientReport = ["sh", "-c", "printf '%s' \"$SSH_CLIENT\""]

    static func establishedSSHConnections(_ table: String, port: Int) -> Int {
        let hex = String(format: "%04X", port)
        return table.split(separator: "\n").filter { row in
            let fields = row.split(separator: " ", omittingEmptySubsequences: true)
            guard fields.count > 3, fields[1].hasSuffix(":" + hex) else { return false }
            return fields[3] == "01"
        }.count
    }

    static func failure(of work: () async throws -> Void) async -> TransportFailure? {
        do {
            try await work()
            return nil
        } catch let failure as TransportFailure {
            return failure
        } catch {
            return TransportFailure(stateID: "test.unexpectedError", detail: "\(error)")
        }
    }

    static func eventually(
        turns: Int = 500,
        tick: Duration = .milliseconds(20),
        _ condition: @Sendable () async -> Bool
    ) async -> Bool {
        for _ in 0..<turns {
            if await condition() { return true }
            try? await Task.sleep(for: tick)
        }
        return await condition()
    }

    static func stateID<Value>(of task: Task<Value, any Error>) async -> String? {
        do {
            _ = try await task.value
            return nil
        } catch let error as any UserFacingError {
            return error.stateID
        } catch {
            return "test.unexpectedError"
        }
    }

    static func settles(
        within turns: Int = 20_000,
        _ condition: @Sendable () async -> Bool
    ) async -> Bool {
        for _ in 0..<turns {
            if await condition() { return true }
            await Task.yield()
        }
        return await condition()
    }
}
