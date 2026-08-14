import AnySSHUI
import SwiftUI

struct LiveActivityTransportLine: View {
    let state: String
    let agentState: String

    var body: some View {
        HStack(spacing: Theme.Space.step1) {
            StatusDot(
                color: LiveActivityStatus.color(for: state),
                label: "Connection",
                value: state,
                accessibilityIdentifier: UIIdentifier.Session.activityTransportDot
            )
            Text(state)
                .font(Theme.code())
                .foregroundStyle(Theme.text.tertiary)
                .lineLimit(1)
            agent
        }
    }

    @ViewBuilder
    private var agent: some View {
        if let label = LiveActivityStatus.agentLabel(for: agentState),
            let color = LiveActivityStatus.agentColor(for: agentState)
        {
            Text(Theme.metaSeparator)
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.tertiary)
            StatusDot(
                color: color,
                label: "Agent",
                value: label,
                accessibilityIdentifier: UIIdentifier.Session.activityAgentDot
            )
            Text(label)
                .font(Theme.code())
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }
}
