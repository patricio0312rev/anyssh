import AnySSHCore
import AnySSHMocks
import AnySSHUI
import Sessions
import SwiftUI

struct SessionsReconnectScenario: View {
    let failure: ErrorState?

    var body: some View {
        ZStack {
            Theme.Code.canvas.ignoresSafeArea()
            VStack(spacing: Theme.Space.step4) {
                Spacer(minLength: 0)
                SessionConnectionStatusLabel(state: state)
                SessionConnectionChrome(
                    failure: failure,
                    capabilities: SessionScenario.multiplexed,
                    reconnectState: .resumable,
                    attemptCount: 2,
                    canRetry: true,
                    onRetry: {}
                )
                Spacer(minLength: 0)
            }
        }
    }

    private var state: TransportState {
        failure == nil
            ? .disconnected(.backgrounded)
            : .disconnected(.failed(stateID: ErrorState.transport(.connectionRefused).stateID))
    }
}
