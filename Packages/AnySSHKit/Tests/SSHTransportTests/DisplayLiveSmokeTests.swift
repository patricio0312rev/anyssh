import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: LiveHost.isDevelopmentHostReachable))
struct DisplayLiveSmokeTests {
    @Test func opensAShellOnTheDevelopmentHostAndRecordsItsRoundTrip() async throws {
        let host = LiveHost.development
        let sink = ShellSink()
        let transport = SSHTerminalTransport(
            target: SessionTarget(host: host.host, port: Int(host.port)),
            username: host.username,
            credential: .privateKey(AuthSupport.key(host.privateKeyPath)),
            hostKeys: MemoryHostKeyStore(),
            configuration: DisplayTransportConfiguration(session: AuthSupport.patient)
        )
        await transport.setSink(sink)
        await transport.setDelegate(DisplayDelegate())

        let opening = ContinuousClock.now
        try await transport.start(size: TerminalSize(columns: 100, rows: 40))
        let opened = opening.duration(to: .now)

        try await transport.send(Array("stty -onlcr -echo; PS1=''; printf 'ANYSSH-%s\\n' GO\n".utf8)[...])
        #expect(await sink.waitFor("ANYSSH-GO"))

        let sending = ContinuousClock.now
        try await transport.send(Array("printf 'ANYSSH-%s\\n' READY\n".utf8)[...])
        #expect(await sink.waitFor("ANYSSH-READY"))
        let markerRoundTrip = sending.duration(to: .now)

        let resizing = ContinuousClock.now
        try await transport.resize(to: TerminalSize(columns: 120, rows: 30))
        let resized = resizing.duration(to: .now)

        try LiveArtifact.write(
            "live-p12.json",
            [
                "host": host.host,
                "user": host.username,
                "term": "xterm-256color",
                "openedSize": "100x40",
                "resizedSize": "120x30",
                "shellOpenMilliseconds": opened.milliseconds,
                "markerRoundTripMilliseconds": markerRoundTrip.milliseconds,
                "resizeMilliseconds": resized.milliseconds,
                "receivedChunks": await sink.chunks,
                "receivedBytes": await sink.bytes.count,
                "recordedAt": ISO8601DateFormatter().string(from: Date()),
            ]
        )
        await transport.close()
    }
}
