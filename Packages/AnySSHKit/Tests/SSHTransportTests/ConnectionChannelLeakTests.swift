import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: AuthEnvironment.isAvailable))
struct ConnectionChannelLeakTests {
    @Test func fiftyCancelledBatchesNeverLeaveAChannelBehind() async throws {
        let (connection, _) = try await ConnectionTestbed.opened()
        defer { Task { await connection.close() } }

        for index in 0..<50 {
            let task = Task {
                try await LiveSetupRetry.controlRun(channelCounters: {
                    (connection.ledger.openCount, connection.ledger.closeCount)
                }) {
                    try await connection.run(ConnectionTestbed.blocking("leak-\(index)"))
                }
            }
            #expect(await ConnectionTestbed.eventually { connection.ledger.openCount == 1 })

            await connection.cancelAll(reason: .cancelledBySwitch)

            #expect(
                await ConnectionTestbed.stateID(of: task)
                    == ErrorState.transport(.cancelledBySwitch).stateID
            )
            #expect(connection.ledger.openCount == 0)
        }

        #expect(connection.ledger.peakOpenCount <= 4)
        #expect(connection.ledger.closeCount == 50)
        #expect(connection.ledger.openCount == 0)

        let response = try await connection.run(
            ConnectionTestbed.batch("final", ["sh", "-c", "printf done"])
        )
        #expect(ConnectionTestbed.text(response, "final") == "done")
        #expect(connection.ledger.openCount == 0)
        #expect(await connection.controlState == .connected)
    }
}
