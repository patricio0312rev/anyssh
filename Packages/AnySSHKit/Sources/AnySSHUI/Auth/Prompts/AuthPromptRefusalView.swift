import AnySSHCore
import SwiftUI

public struct AuthPromptRefusalView: View {
    let state: AuthErrorState
    let dismiss: () -> Void

    public init(state: AuthErrorState, dismiss: @escaping () -> Void) {
        self.state = state
        self.dismiss = dismiss
    }

    public var body: some View {
        ErrorStateView(state: ErrorState.auth(state), recover: dismiss)
    }
}
