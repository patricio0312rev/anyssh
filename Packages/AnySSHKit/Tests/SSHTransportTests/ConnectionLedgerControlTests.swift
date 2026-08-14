import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite struct ConnectionLedgerControlTests {
    @Test func theLedgerReportsAChannelThatIsNeverClosed() {
        let ledger = ControlChannelLedger()

        let leaked = ledger.opened()
        let returned = ledger.opened()
        ledger.closed(returned)

        #expect(ledger.openCount == 1)
        #expect(ledger.closeCount == 1)
        #expect(ledger.peakOpenCount == 2)

        ledger.closed(leaked)
        #expect(ledger.openCount == 0)
    }

    @Test func closingTheSameChannelTwiceCountsOnce() {
        let ledger = ControlChannelLedger()
        let receipt = ledger.opened()

        ledger.closed(receipt)
        ledger.closed(receipt)

        #expect(ledger.closeCount == 1)
        #expect(ledger.openCount == 0)
    }

    @Test func thePeakIsRecordedRatherThanSampled() {
        let ledger = ControlChannelLedger()
        let receipts = (0..<4).map { _ in ledger.opened() }
        for receipt in receipts { ledger.closed(receipt) }

        #expect(ledger.openCount == 0)
        #expect(ledger.peakOpenCount == 4)
        #expect(ledger.closeCount == 4)
    }
}

@Suite(.enabled(if: AuthEnvironment.isAvailable))
struct ConnectionMaxSessionsTests {
    @Test func holdingTwelveChannelsOpenAtOnceIsRefusedByTheServer() async throws {
        let (connection, _) = try await ConnectionTestbed.opened()
        defer { Task { await connection.close() } }
        _ = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await connection.run(ConnectionTestbed.batch("warm", ["true"]))
        }

        let refusals = ResolutionCounter()
        let tasks = (0..<12).map { index in
            Task { [refusals] in
                do {
                    return try await connection.run(ConnectionTestbed.blocking("hold-\(index)"))
                } catch let failure as TransportFailure {
                    if failure.stateID == "transport.channelRejected" { refusals.record() }
                    throw failure
                }
            }
        }
        #expect(await ConnectionTestbed.eventually { refusals.value > 0 })
        let granted = connection.ledger.peakOpenCount

        await connection.cancelAll(reason: .cancelledBySwitch)
        for task in tasks { _ = await task.result }

        #expect(granted <= 10)
        #expect(granted >= 8)
        #expect(refusals.value > 0)
        #expect(connection.ledger.openCount == 0)
        #expect(await connection.controlState == .connected)
    }
}
