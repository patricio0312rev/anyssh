import ActivityKit
import AnySSHUI
import SwiftUI
import WidgetKit

struct AnySSHLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityAttributes.self) { context in
            LiveActivityLockScreenView(state: context.state, isStale: context.isStale)
                .activitySystemActionForegroundColor(Theme.text.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityAppMark(size: LiveActivityMetrics.expandedMark)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveActivityUptime(seconds: context.state.uptime)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedContent(state: context.state)
                }
            } compactLeading: {
                LiveActivityAppMark(size: LiveActivityMetrics.compactMark)
            } compactTrailing: {
                LiveActivityUptime(seconds: context.state.uptime)
            } minimal: {
                LiveActivityAppMark(size: LiveActivityMetrics.compactMark)
            }
        }
    }
}

private struct ExpandedContent: View {
    let state: LiveActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step1) {
            Text(state.remoteName)
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.primary)
                .lineLimit(1)
                .truncationMode(.middle)
            LiveActivityTransportLine(state: state.transportState, agentState: state.agentState)
            if let notification = state.notification {
                LiveActivityNotificationLine(text: notification)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
