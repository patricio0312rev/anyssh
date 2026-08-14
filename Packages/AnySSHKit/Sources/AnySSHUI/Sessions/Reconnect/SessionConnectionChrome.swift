import AnySSHCore
import Sessions
import SwiftUI

public struct SessionConnectionChrome: View {
    private let failure: ErrorState?
    private let capabilities: TransportCapabilities?
    private let reconnectState: SessionReconnectState?
    private let attemptCount: Int
    private let canRetry: Bool
    private let onRetry: () -> Void

    public init(
        failure: ErrorState?,
        capabilities: TransportCapabilities?,
        reconnectState: SessionReconnectState?,
        attemptCount: Int,
        canRetry: Bool,
        onRetry: @escaping () -> Void
    ) {
        self.failure = failure
        self.capabilities = capabilities
        self.reconnectState = reconnectState
        self.attemptCount = attemptCount
        self.canRetry = canRetry
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let failure {
                failurePanel(failure)
            } else if let capabilities, let reconnectState, reconnectState.offersReconnect {
                SessionReconnectPresenter(
                    capabilities: capabilities,
                    reconnectState: reconnectState,
                    attemptCount: attemptCount,
                    onReconnect: onRetry
                )
            }
        }
    }

    private func failurePanel(_ failure: ErrorState) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Theme.Space.step3) {
                Text(failure.copy.title)
                    .font(Theme.Text.sectionHeader)
                    .foregroundStyle(Theme.text.primary)
                Text(failure.copy.body)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
                if canRetry {
                    SheetActionButton(
                        failure.copy.recoveryLabel,
                        emphasis: .primary,
                        accessibilityIdentifier: UIIdentifier.Session.reconnect,
                        action: onRetry
                    )
                }
            }
        }
        .padding(.horizontal, Theme.Space.screenMargin)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(failure.accessibilityIdentifier)
    }
}

public struct SessionConnectionStatusLabel: View {
    private let state: TransportState

    public init(state: TransportState) {
        self.state = state
    }

    public var body: some View {
        HStack(spacing: Theme.Space.step1) {
            StatusDot(
                color: state.statusColor,
                label: "Connection status",
                value: state.label,
                accessibilityIdentifier: UIIdentifier.Session.statusDot
            )
            Text(state.label)
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(UIIdentifier.Session.statusLabel)
        .accessibilityLabel(state.label)
    }
}
