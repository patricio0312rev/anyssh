import AnySSHUI
import SwiftUI
import WidgetKit

struct LiveActivityLockScreenView: View {
    let state: LiveActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step2) {
            HStack(spacing: Theme.Space.step3) {
                LiveActivityAppMark(size: LiveActivityMetrics.lockScreenMark)
                VStack(alignment: .leading, spacing: Theme.Space.step1) {
                    Text(state.remoteName)
                        .font(Theme.Text.body)
                        .foregroundStyle(Theme.text.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    LiveActivityTransportLine(
                        state: state.transportState,
                        agentState: state.agentState
                    )
                }
                Spacer(minLength: Theme.Space.step2)
                LiveActivityUptime(seconds: state.uptime, showsLabel: true)
            }
            if let notification = state.notification {
                Divider().overlay(Theme.separator)
                LiveActivityNotificationLine(text: notification)
            }
        }
        .padding(Theme.Space.cardPadding)
        .opacity(isStale ? LiveActivityMetrics.staleOpacity : 1)
        .containerBackground(.clear, for: .widget)
    }
}
