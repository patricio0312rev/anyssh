import AnySSHCore
import Sessions
import SwiftUI

public struct SessionReconnectPresenter: View {
    private let capabilities: TransportCapabilities
    private let reconnectState: SessionReconnectState
    private let attemptCount: Int
    private let onReconnect: () -> Void

    public init(
        capabilities: TransportCapabilities,
        reconnectState: SessionReconnectState,
        attemptCount: Int,
        onReconnect: @escaping () -> Void
    ) {
        self.capabilities = capabilities
        self.reconnectState = reconnectState
        self.attemptCount = attemptCount
        self.onReconnect = onReconnect
    }

    public var body: some View {
        let survival = ReconnectSurvivalCopy.state(for: capabilities)
        SurfaceCard {
            VStack(alignment: .leading, spacing: Theme.Space.step3) {
                Text(survival.copy.title)
                    .font(Theme.Text.sectionHeader)
                    .foregroundStyle(Theme.text.primary)
                Text(survival.copy.body)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
                    .accessibilityIdentifier(survival.accessibilityIdentifier)
                if attemptCount > 0 {
                    Text("Attempts: \(attemptCount)")
                        .font(Theme.Text.caption)
                        .foregroundStyle(Theme.text.tertiary)
                        .accessibilityIdentifier(UIIdentifier.Session.reconnectAttempts)
                }
                if reconnectState.offersReconnect {
                    SheetActionButton(
                        actionLabel(for: reconnectState, survival: survival),
                        emphasis: .primary,
                        accessibilityIdentifier: UIIdentifier.Session.reconnect,
                        action: onReconnect
                    )
                }
            }
        }
        .padding(.horizontal, Theme.Space.screenMargin)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UIIdentifier.Session.reconnectCard)
    }

    private func actionLabel(
        for state: SessionReconnectState,
        survival: ErrorState
    ) -> String {
        switch state {
        case .resumable:
            ErrorState.session(.survivalMultiplexed).copy.recoveryLabel
        default:
            survival.copy.recoveryLabel
        }
    }
}
