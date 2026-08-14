import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: AuthEnvironment.isAvailable))
struct DisplayTransportTests {
    @Test func aShellDeliversItsBytesExactly() async throws {
        let sink = ShellSink()
        let transport = await DisplayTestbed.transport(sink: sink)
        try await transport.start(size: TerminalSize(columns: 80, rows: 24))
        defer { Task { await transport.close() } }

        #expect(try await DisplayTestbed.quieten(transport) { await sink.waitFor($0) })
        await sink.clear()

        try await DisplayTestbed.send(transport, "printf 'ANYSSH-%s\\n' READY\n")

        #expect(await sink.waitFor("ANYSSH-READY\n"))
        #expect(await sink.bytes == Array("ANYSSH-READY\n".utf8))
        #expect(await transport.state == .connected)
    }

    @Test func theRemoteOpensAtTheGeometryItWasGiven() async throws {
        let sink = ShellSink()
        let transport = await DisplayTestbed.transport(sink: sink)
        try await transport.start(size: TerminalSize(columns: 132, rows: 43))
        defer { Task { await transport.close() } }

        #expect(try await DisplayTestbed.quieten(transport) { await sink.waitFor($0) })
        await sink.clear()
        try await DisplayTestbed.send(transport, "stty size\n")

        #expect(await sink.waitFor("\n"))
        #expect(await sink.text.trimmingCharacters(in: .whitespacesAndNewlines) == "43 132")
    }

    @Test func aResizeReachesTheRemoteTty() async throws {
        let sink = ShellSink()
        let transport = await DisplayTestbed.transport(sink: sink)
        try await transport.start(size: TerminalSize(columns: 80, rows: 24))
        defer { Task { await transport.close() } }
        #expect(try await DisplayTestbed.quieten(transport) { await sink.waitFor($0) })

        let resized = TerminalSize(columns: 100, rows: 40, pixelWidth: 900, pixelHeight: 720)
        try await transport.resize(to: resized)
        await sink.clear()
        try await DisplayTestbed.send(transport, "stty size\n")

        #expect(await sink.waitFor("\n"))
        #expect(await sink.text.trimmingCharacters(in: .whitespacesAndNewlines) == "40 100")
        #expect(await transport.size == resized)
    }

    @Test func aResizeRaisesSigwinchOnTheRemote() async throws {
        let sink = ShellSink()
        let transport = await DisplayTestbed.transport(sink: sink)
        try await transport.start(size: TerminalSize(columns: 80, rows: 24))
        defer { Task { await transport.close() } }
        #expect(try await DisplayTestbed.quieten(transport) { await sink.waitFor($0) })

        try await DisplayTestbed.send(
            transport,
            "trap 'printf \"ANYSSH-WINCH %s\\n\" \"$(stty size)\"' WINCH; printf 'ANYSSH-ARMED\\n'\n"
        )
        #expect(await sink.waitFor("ANYSSH-ARMED\n"))
        await sink.clear()

        try await transport.resize(to: TerminalSize(columns: 120, rows: 30))
        try await DisplayTestbed.send(transport, "printf 'ANYSSH-POKE\\n'\n")

        #expect(await sink.waitFor("ANYSSH-POKE", ceiling: .seconds(20)))
        #expect(await sink.text.contains("ANYSSH-WINCH 30 120"))
    }

    @Test func anInterruptGetsThroughWhileTheConsumerIsSaturated() async throws {
        let sink = SaturatingSink()
        let transport = await DisplayTestbed.transport(sink: sink)
        try await transport.start(size: TerminalSize(columns: 80, rows: 24))
        defer { Task { await transport.close() } }
        #expect(try await DisplayTestbed.quieten(transport) { await sink.waitFor($0) })

        try await DisplayTestbed.send(transport, "yes ANYSSH-FLOOD\n")
        #expect(await sink.waitUntilSuspended())

        let started = ContinuousClock.now
        try await transport.send([0x03][...])
        #expect(await sink.isSuspended)
        #expect(await sink.suspensions > 0)

        await sink.release()
        try await DisplayTestbed.send(transport, "printf 'ANYSSH-%s\\n' INT\n")
        #expect(await sink.waitFor("ANYSSH-INT"))

        let chunks = await sink.chunks
        let accepted = await sink.acceptedBytes
        #expect(chunks * 64 < accepted)

        try LiveArtifact.write(
            "e4-p12-interrupt.json",
            [
                "acceptedBytes": accepted,
                "chunks": chunks,
                "meanChunkBytes": accepted / max(1, chunks),
                "suspensions": await sink.suspensions,
                "interruptToPromptMilliseconds": started.duration(to: .now).milliseconds,
            ]
        )
    }

    @Test func closingStopsTheTerminalAndRefusesFurtherWrites() async throws {
        let sink = ShellSink()
        let delegate = DisplayDelegate()
        let transport = await DisplayTestbed.transport(sink: sink, delegate: delegate)
        try await transport.start(size: .standard)
        #expect(await transport.isReading)

        await transport.close()

        #expect(await transport.state == .disconnected(.closedByUser))
        #expect(await transport.isReading == false)
        #expect(delegate.states.contains(.connected))
        #expect(delegate.states.last == .disconnected(.closedByUser))

        let failure = await DisplayTestbed.failure { try await DisplayTestbed.send(transport, "echo\n") }
        #expect(failure?.stateID == "transport.notConnected")
    }

    @Test func aShellThatExitsEndsTheTerminalAsClosedByRemote() async throws {
        let sink = ShellSink()
        let delegate = DisplayDelegate()
        let transport = await DisplayTestbed.transport(sink: sink, delegate: delegate)
        try await transport.start(size: .standard)

        try await DisplayTestbed.send(transport, "exit\n")

        #expect(await DisplayTestbed.leftConnected(transport))
        #expect(await transport.state == .disconnected(.closedByRemote))
        #expect(await transport.isReading == false)
        #expect(delegate.states.last == .disconnected(.closedByRemote))
    }

    @Test func aTerminalWithNoDelegateRefusesAnUnknownHost() async throws {
        let sink = ShellSink()
        let transport = await DisplayTestbed.transport(sink: sink, delegate: nil)

        let failure = await DisplayTestbed.failure { try await transport.start(size: .standard) }

        #expect(failure?.stateID == "trust.cancelled")
        #expect(await transport.state == .disconnected(.failed(stateID: "trust.cancelled")))
        #expect(await transport.isReading == false)
    }

}
