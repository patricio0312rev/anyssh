import AnySSHCore
import SwiftUI

struct RemotesFailureState: View {
    private let state = ErrorState.secrets(.migrationFailed)

    let message: String

    var body: some View {
        VStack(spacing: Theme.Space.step4) {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .scaledToFit()
                .frame(width: Theme.Space.iconTile, height: Theme.Space.iconTile)
                .foregroundStyle(Theme.status.error)
            Text(state.copy.title)
                .font(Theme.Text.screenTitle)
                .foregroundStyle(Theme.text.primary)
                .multilineTextAlignment(.center)
            Text(state.copy.body)
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Space.step6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.surface.base)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(state.accessibilityIdentifier)
        .accessibilityValue(message)
    }
}

#Preview("RemotesFailureState") {
    ThemedRoot {
        RemotesFailureState(message: "The store could not be read")
    }
}
