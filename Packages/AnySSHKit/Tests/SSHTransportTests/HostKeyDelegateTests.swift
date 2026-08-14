import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

private actor Latch {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func open() {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}

private actor RecordingTransport: TerminalTransport {
    nonisolated let kind = TransportKind.ssh
    nonisolated let capabilities = TransportCapabilities(
        roaming: false, serverSideResume: false, execChannels: true, portForwarding: true)

    private(set) var state = TransportState.connecting
    private(set) var sentByteCount = 0

    func setDelegate(_ delegate: any TerminalTransportDelegate) {}
    func setSink(_ sink: any ByteSink) {}
    func start(size: TerminalSize) async throws {}
    func resize(to size: TerminalSize) async throws {}
    func close() async { state = .disconnected(.closedByUser) }

    func send(_ bytes: ArraySlice<UInt8>) async throws {
        sentByteCount += bytes.count
    }
}

private final class SuspendingDelegate: TerminalTransportDelegate {
    let arrived = Latch()
    let release = Latch()

    private let verdict: HostKeyVerdict

    init(_ verdict: HostKeyVerdict) {
        self.verdict = verdict
    }

    func transport(
        _ transport: any TerminalTransport,
        verify key: HostKey,
        status: KnownHostStatus
    ) async -> HostKeyVerdict {
        await arrived.open()
        await release.wait()
        return verdict
    }

    func transport(
        _ transport: any TerminalTransport,
        answer round: AuthPromptRound
    ) async -> AuthPromptAnswer {
        .cancelled
    }

    func transport(_ transport: any TerminalTransport, didChange state: TransportState) async {}
}

@Suite struct HostKeyDelegateTests {
    private let host = "trust.example"

    @Test func theDecisionStaysSuspendedUntilTheDelegateAnswers() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        let transport = RecordingTransport()
        let delegate = SuspendingDelegate(.accept(remember: true))
        let trust = HostKeyTrust(
            store: store, question: .delegate(delegate, of: transport))

        async let outcome = trust.evaluate(HostKeyFixture.ed25519, host: host, port: 22)
        await delegate.arrived.wait()

        #expect(await transport.sentByteCount == 0)
        #expect(directory.knownHostsText.isEmpty)

        await delegate.release.open()
        #expect(try await outcome == .accepted(remembered: true))
        #expect(try await store.knownKey(host: host, port: 22)?.raw == HostKeyFixture.ed25519.raw)
    }

    @Test func aDelegateRefusalTravelsBackAsTheRefusedState() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        let transport = RecordingTransport()
        let delegate = SuspendingDelegate(.reject)
        await delegate.release.open()

        let outcome = try await HostKeyTrust(store: store, question: .delegate(delegate, of: transport))
            .evaluate(HostKeyFixture.ed25519, host: host, port: 22)

        #expect(outcome == .refused(.rejected))
        #expect(directory.knownHostsText.isEmpty)
    }

    @Test func theUnattendedQuestionRefuses() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)

        let outcome = try await HostKeyTrust(store: store, question: .unattended)
            .evaluate(HostKeyFixture.ed25519, host: host, port: 22)

        #expect(outcome == .refused(.cancelled))
        #expect(directory.knownHostsText.isEmpty)
    }
}
