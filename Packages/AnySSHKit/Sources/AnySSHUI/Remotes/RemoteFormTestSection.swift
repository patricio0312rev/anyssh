import AnySSHCore
import SwiftUI

struct RemoteFormTestSection: View {
    @Bindable var model: RemoteFormModel

    var body: some View {
        Section {
            Button {
                Task { await model.testConnection() }
            } label: {
                if model.isTesting {
                    LoadingView(.inline)
                } else {
                    Text("Test Connection")
                }
            }
            .disabled(!model.canTest)
            .accessibilityIdentifier(UIIdentifier.RemoteForm.testConnection)

            if let outcome = model.testOutcome {
                Text(outcome.label)
                    .font(Theme.Text.body)
                    .foregroundStyle(outcome.tint)
                    .accessibilityIdentifier(UIIdentifier.RemoteForm.testResult)
            }
        }
        .listRowBackground(Theme.surface.raised)
    }
}

extension ConnectionTestOutcome {
    var label: String {
        switch self {
        case .authenticated:
            "Authenticated. The host accepted these credentials."
        case .unreachable(let state):
            state.copy.title
        case .authenticationFailed(let state):
            state.copy.title
        }
    }

    var tint: Color {
        switch self {
        case .authenticated: Theme.status.online
        case .unreachable, .authenticationFailed: Theme.status.error
        }
    }
}
