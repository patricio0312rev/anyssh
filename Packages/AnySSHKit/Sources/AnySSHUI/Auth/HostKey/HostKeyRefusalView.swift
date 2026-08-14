import AnySSHCore
import SwiftUI

public struct HostKeyRefusalView: View {
    let state: TrustErrorState
    let dismiss: () -> Void

    public init(state: TrustErrorState, dismiss: @escaping () -> Void) {
        self.state = state
        self.dismiss = dismiss
    }

    public var body: some View {
        ErrorStateView(state: ErrorState.trust(state), recover: dismiss)
    }
}
