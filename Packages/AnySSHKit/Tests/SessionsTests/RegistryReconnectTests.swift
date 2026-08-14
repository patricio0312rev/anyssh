import AnySSHCore
import Testing

@testable import Sessions

extension SessionRegistryTests {
    @Test(arguments: RegistryReconnectCase.table)
    func theRegistryDerivesTheReconnectStateTheTableNames(_ row: RegistryReconnectCase) {
        var registry = SessionRegistry()
        registry.open(
            RegistryFixture.record("a", state: row.state, capabilities: row.capabilities)
        )

        let derived = registry.reconnectState(for: RegistryFixture.id("a"))

        #expect(derived == row.expected)
        #expect(derived?.offersReconnect == row.offersReconnect)
        #expect(derived?.isLive == (row.expected == .live))
    }

    @Test func theReconnectTableCoversEveryStateAndEveryReason() {
        let families = Set(
            RegistryReconnectCase.table.map { RegistryReconnectCase.family(of: $0.state) }
        )
        #expect(families.count == 6)

        let reasons = Set(
            RegistryReconnectCase.table.compactMap { row -> String? in
                guard case .disconnected(let reason) = row.state else { return nil }
                return RegistryReconnectCase.reason(of: reason)
            }
        )
        #expect(reasons.count == 5)
    }

    @Test func anUnknownSessionHasNoReconnectState() {
        let registry = SessionRegistry()

        #expect(registry.reconnectState(for: RegistryFixture.id("missing")) == nil)
    }

    @Test func onlyServerSideResumeMakesADropResumable() {
        let dropped = TransportState.disconnected(.backgrounded)

        #expect(
            SessionReconnectState.derived(from: dropped, capabilities: RegistryFixture.ssh)
                == .reconnectable
        )
        #expect(
            SessionReconnectState.derived(from: dropped, capabilities: RegistryFixture.multiplexed)
                == .resumable
        )
    }
}
