import AnySSHCore
import Foundation
import Testing

@testable import Sessions

struct ReconnectPolicyCase: Sendable, CustomStringConvertible {
    let name: String
    let capabilities: TransportCapabilities
    let expectedBody: String
    let expectedStateID: String

    var description: String { name }
}

@Suite struct ReconnectPolicyTests {
    private static let documentURL = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "docs/error-states.md")

    private static let matrix: [ReconnectPolicyCase] = [
        ReconnectPolicyCase(
            name: "SSH",
            capabilities: TransportCapabilities(
                roaming: false,
                serverSideResume: false,
                execChannels: true,
                portForwarding: true
            ),
            expectedBody:
                "Backgrounding ends this session. Work continues on the host only if it is inside tmux or herdr.",
            expectedStateID: "session.survivalSSH"
        ),
        ReconnectPolicyCase(
            name: "SSH attached to a multiplexer",
            capabilities: TransportCapabilities(
                roaming: false,
                serverSideResume: true,
                execChannels: true,
                portForwarding: true
            ),
            expectedBody: "Reattaches on return. Scrollback is preserved on the host.",
            expectedStateID: "session.survivalMultiplexed"
        ),
        ReconnectPolicyCase(
            name: "synthetic roaming transport",
            capabilities: TransportCapabilities(
                roaming: true,
                serverSideResume: true,
                execChannels: false,
                portForwarding: false
            ),
            expectedBody:
                "Survives sleep and network change. Scrollback from before the drop is lost unless you are in a multiplexer.",
            expectedStateID: "session.survivalRoaming"
        ),
    ]

    @Test(arguments: matrix)
    func theCardShowsTheExactRegistryString(_ row: ReconnectPolicyCase) throws {
        let documented = try Self.body(for: row.expectedStateID)
        let state = ReconnectSurvivalCopy.state(for: row.capabilities)

        #expect(state.stateID == row.expectedStateID)
        #expect(state.copy.body == row.expectedBody)
        #expect(state.copy.body == documented)
        #expect(ReconnectSurvivalCopy.body(for: row.capabilities) == row.expectedBody)
    }

    @Test func backgroundedSSHReconnectsAutomaticallyWithinTheBound() {
        let policy = ReconnectPolicy(
            backoff: ReconnectBackoff(
                maxAttempts: 3,
                baseDelay: .milliseconds(10),
                maxDelay: .milliseconds(40)
            )
        )
        let decision = policy.decision(
            state: .disconnected(.backgrounded),
            capabilities: .ssh,
            recordedAttempts: 0
        )
        guard case .reconnect(let attempt, let delay) = decision else {
            Issue.record("expected automatic reconnect, got \(decision)")
            return
        }
        #expect(attempt == 1)
        #expect(delay == .zero)
    }

    @Test func closedByRemoteWaitsForTheUserUntilAttemptsExhaust() {
        let policy = ReconnectPolicy(
            backoff: ReconnectBackoff(
                maxAttempts: 2,
                baseDelay: .milliseconds(10),
                maxDelay: .milliseconds(40)
            )
        )
        #expect(
            policy.decision(
                state: .disconnected(.closedByRemote),
                capabilities: .ssh,
                recordedAttempts: 0
            ) == .waitForUser
        )
        #expect(
            policy.decision(
                state: .disconnected(.closedByRemote),
                capabilities: .ssh,
                recordedAttempts: 2
            ) == .exhausted
        )
    }

    @Test func roamingTransportReconnectsOnDrop() {
        let roaming = TransportCapabilities(
            roaming: true,
            serverSideResume: true,
            execChannels: false,
            portForwarding: false
        )
        let policy = ReconnectPolicy()
        let decision = policy.decision(
            state: .disconnected(.closedByRemote),
            capabilities: roaming,
            recordedAttempts: 1
        )
        guard case .reconnect(let attempt, _) = decision else {
            Issue.record("expected roaming reconnect, got \(decision)")
            return
        }
        #expect(attempt == 2)
    }

    @Test func backoffDoublesUntilTheCap() {
        let backoff = ReconnectBackoff(
            maxAttempts: 6,
            baseDelay: .milliseconds(500),
            maxDelay: .seconds(2)
        )
        #expect(backoff.delay(beforeAttempt: 1) == .zero)
        #expect(backoff.delay(beforeAttempt: 2) == .milliseconds(500))
        #expect(backoff.delay(beforeAttempt: 3) == .seconds(1))
        #expect(backoff.delay(beforeAttempt: 4) == .seconds(2))
        #expect(backoff.delay(beforeAttempt: 5) == .seconds(2))
        #expect(backoff.allows(attempt: 6))
        #expect(!backoff.allows(attempt: 7))
    }

    private static func body(for stateID: String) throws -> String {
        let text = try String(contentsOf: documentURL, encoding: .utf8)
        for line in text.split(separator: "\n") where line.hasPrefix("| `") {
            let cells = line.split(separator: "|", omittingEmptySubsequences: false)
                .dropFirst()
                .dropLast()
                .map {
                    $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "`", with: "")
                }
            guard cells.count == 7, cells[0] == stateID else { continue }
            return cells[3]
        }
        Issue.record("missing docs/error-states.md row for \(stateID)")
        return ""
    }
}
