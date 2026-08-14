import AnySSHCore
import Foundation

@testable import SSHTransport

enum DisplayTestbed {
    static func transport(
        sink: any ByteSink,
        delegate: (any TerminalTransportDelegate)? = DisplayDelegate(),
        user: String = "keyuser",
        credential: AuthCredential? = nil
    ) async -> SSHTerminalTransport {
        let testbed = AuthEnvironment.testbed
        let transport = SSHTerminalTransport(
            target: SessionTarget(
                host: testbed?.host ?? TestbedHost.sshd.host,
                port: testbed?.port ?? Int(TestbedHost.sshd.port)
            ),
            username: user,
            credential: credential ?? .privateKey(AuthSupport.key(AuthEnvironment.ed25519)),
            hostKeys: MemoryHostKeyStore(),
            configuration: DisplayTransportConfiguration(session: AuthSupport.patient)
        )
        await transport.setSink(sink)
        if let delegate {
            await transport.setDelegate(delegate)
        }
        return transport
    }

    static func send(_ transport: SSHTerminalTransport, _ line: String) async throws {
        try await transport.send(Array(line.utf8)[...])
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

    static func leftConnected(
        _ transport: SSHTerminalTransport,
        ceiling: Duration = .seconds(60)
    ) async -> Bool {
        let limit = ContinuousClock.now + ceiling
        while await transport.state == .connected {
            guard ContinuousClock.now < limit else { return false }
            await Task.yield()
        }
        return true
    }

    static func quieten(
        _ transport: SSHTerminalTransport,
        waitFor: (String) async -> Bool
    ) async throws -> Bool {
        try await send(transport, "stty -onlcr -echo; PS1=''; printf 'ANYSSH-GO\\n'\n")
        return await waitFor("ANYSSH-GO\n")
    }
}
