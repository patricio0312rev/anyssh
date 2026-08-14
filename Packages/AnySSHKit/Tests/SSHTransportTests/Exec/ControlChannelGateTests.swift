import AnySSHCore
import Testing

@testable import SSHTransport

@Suite struct ControlChannelGateTests {
    @Test func aFifthAcquireWaitsUntilASlotFrees() async throws {
        let gate = ControlChannelGate()
        let first = try await gate.acquire()
        let second = try await gate.acquire()
        let third = try await gate.acquire()
        let fourth = try await gate.acquire()
        #expect(await gate.openCount == 4)

        let waiter = Task { try await gate.acquire(timeout: .seconds(2)) }
        #expect(await ConnectionTestbed.settles { await gate.waiterCount == 1 })

        await gate.release(first)
        let fifth = try await waiter.value

        #expect(fifth != first)
        #expect(await gate.openCount == 4)
        #expect(await gate.peakOpenCount == 4)

        for channel in [second, third, fourth, fifth] {
            await gate.release(channel)
        }
        #expect(await gate.openCount == 0)
    }

    @Test func aPinnedQueueTimesOutWithTheNamedFailure() async throws {
        let gate = ControlChannelGate()
        var held = [Int]()
        for _ in 0..<4 {
            held.append(try await gate.acquire())
        }

        await #expect(throws: TransportFailure.channelQueueTimeout) {
            _ = try await gate.acquire(timeout: .milliseconds(50))
        }

        for channel in held {
            await gate.release(channel)
        }
        #expect(await gate.openCount == 0)
    }

    @Test func cancellingAWaiterThrowsCancelledBySwitch() async throws {
        let gate = ControlChannelGate()
        var held = [Int]()
        for _ in 0..<4 {
            held.append(try await gate.acquire())
        }

        let waiter = Task { try await gate.acquire(timeout: .seconds(30)) }
        #expect(await ConnectionTestbed.settles { await gate.waiterCount == 1 })
        waiter.cancel()

        #expect(
            await CommandRunnerFixture.stateID(of: waiter)
                == ErrorState.transport(.cancelledBySwitch).stateID
        )
        #expect(await gate.waiterCount == 0)

        for channel in held {
            await gate.release(channel)
        }
    }

    @Test func cancelWaitingFailsEveryQueuedAcquire() async throws {
        let gate = ControlChannelGate()
        var held = [Int]()
        for _ in 0..<4 {
            held.append(try await gate.acquire())
        }

        let waiters = (0..<3).map { _ in
            Task { try await gate.acquire(timeout: .seconds(30)) }
        }
        #expect(await ConnectionTestbed.settles { await gate.waiterCount == 3 })

        await gate.cancelWaiting()

        for waiter in waiters {
            #expect(
                await CommandRunnerFixture.stateID(of: waiter)
                    == ErrorState.transport(.cancelledBySwitch).stateID
            )
        }
        #expect(await gate.waiterCount == 0)

        for channel in held {
            await gate.release(channel)
        }
        #expect(await gate.openCount == 0)
    }

    @Test func beginCancellationRefusesAcquireUntilEnded() async throws {
        let gate = ControlChannelGate()
        let held = try await gate.acquire()
        await gate.beginCancellation()

        let refused = Task { try await gate.acquire(timeout: .milliseconds(50)) }
        #expect(
            await CommandRunnerFixture.stateID(of: refused)
                == ErrorState.transport(.cancelledBySwitch).stateID
        )

        await gate.release(held)
        await gate.endCancellation()

        let after = try await gate.acquire(timeout: .milliseconds(50))
        await gate.release(after)
        #expect(await gate.openCount == 0)
    }
}
