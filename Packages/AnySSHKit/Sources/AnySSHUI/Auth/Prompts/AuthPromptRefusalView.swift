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
        let copy = ErrorState.auth(state).copy
        VStack(alignment: .leading, spacing: Theme.Space.step5) {
            VStack(alignment: .leading, spacing: Theme.Space.step2) {
                Text(copy.title)
                    .font(Theme.Text.screenTitle)
                Text(copy.body)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
            }
            .accessibilityElement(children: .combine)

            Button(copy.recoveryLabel, action: dismiss)
                .buttonStyle(.glass)
                .controlSize(.large)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(UIIdentifier.Auth.submit)
        }
        .padding(Theme.Space.step5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .topLeading) { ScreenMarker(state: ErrorState.auth(state)) }
    }
}
