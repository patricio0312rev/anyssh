import AnySSHCore
import SwiftUI

struct RemotesEmptyState: View {
    private let state = ErrorState.app(.noHostsYet)

    let addHost: () -> Void
    let importKey: () -> Void

    var body: some View {
        VStack(spacing: Theme.Space.step5) {
            Image(systemName: "server.rack")
                .resizable()
                .scaledToFit()
                .frame(width: Theme.Space.iconTile, height: Theme.Space.iconTile)
                .foregroundStyle(Theme.text.secondary)
                .accessibilityLabel(state.copy.title)

            VStack(spacing: Theme.Space.step2) {
                Text(state.copy.title)
                    .font(Theme.Text.screenTitle)
                    .foregroundStyle(Theme.text.primary)
                    .multilineTextAlignment(.center)
                Text(state.copy.body)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(state.accessibilityIdentifier)

            VStack(spacing: Theme.Space.step3) {
                Button(state.copy.recoveryLabel, action: addHost)
                    .buttonStyle(.glassProminent)
                    .tint(Theme.accent)
                    .accessibilityIdentifier(UIIdentifier.Remote.emptyAddHost)
                Button("Import Key", action: importKey)
                    .buttonStyle(.raised)
                    .accessibilityIdentifier(UIIdentifier.Remote.emptyImportKey)
            }
            .controlSize(.large)
        }
        .padding(Theme.Space.step6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.surface.base)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UIIdentifier.Remote.empty)
    }
}

#Preview("RemotesEmptyState") {
    ThemedRoot {
        RemotesEmptyState(addHost: {}, importKey: {})
    }
}
