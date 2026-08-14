import AnySSHCore
import Testing

@testable import SSHTransport

@Suite struct DisplayGuardTests {
    private func transport(sink: (any ByteSink)? = nil) async -> SSHTerminalTransport {
        let transport = SSHTerminalTransport(
            target: SessionTarget(host: "127.0.0.1", port: 65_535),
            username: "nobody",
            credential: .password("unused"),
            hostKeys: MemoryHostKeyStore()
        )
        if let sink {
            await transport.setSink(sink)
        }
        return transport
    }

    @Test func aTerminalWithNowhereToPutItsOutputRefusesToStart() async {
        let transport = await transport()

        let failure = await DisplayTestbed.failure { try await transport.start(size: .standard) }

        #expect(failure?.stateID == "transport.noSink")
        #expect(await transport.state == .idle)
    }

    @Test func aResizeBeforeTheTerminalExistsIsRemembered() async throws {
        let transport = await transport()
        try await transport.resize(to: TerminalSize(columns: 132, rows: 43))

        #expect(await transport.size == TerminalSize(columns: 132, rows: 43))
        #expect(await transport.isReading == false)
    }

    @Test func writingBeforeTheTerminalExistsRefuses() async {
        let transport = await transport(sink: ShellSink())

        let failure = await DisplayTestbed.failure { try await transport.send([0x61][...]) }

        #expect(failure?.stateID == "transport.notConnected")
    }

    @Test func sshRoamsNothingAndResumesNothing() async {
        let transport = await transport()

        #expect(transport.kind == .ssh)
        #expect(transport.capabilities.roaming == false)
        #expect(transport.capabilities.serverSideResume == false)
        #expect(transport.capabilities.execChannels)
        #expect(transport.capabilities.portForwarding)
    }

    @Test func closingATerminalThatNeverStartedIsSafe() async {
        let transport = await transport()
        await transport.close()
        await transport.close()

        #expect(await transport.state == .disconnected(.closedByUser))
    }
}
