import TerminalEmulator
import Testing

@testable import Sessions

@Suite struct SessionStatusTests {
    @Test func onlyConnectedIsLive() {
        #expect(SessionStatus.connected(.standard).isLive)
        #expect(!SessionStatus.connecting.isLive)
        #expect(!SessionStatus.disconnected(reason: "closed").isLive)
    }
}
