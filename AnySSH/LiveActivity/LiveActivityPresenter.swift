import ActivityKit
import AnySSHCore
import Foundation

struct LiveActivityPresenter: ActivityPresenter {
    func start(_ content: AnySSHCore.ActivityContent) async {
        guard Activity<LiveActivityAttributes>.activities.isEmpty else { return }
        let attributes = LiveActivityAttributes(sessionID: content.sessionID.rawValue)
        let activityContent = ActivityContent(
            state: state(from: content),
            staleDate: content.staleDate
        )
        _ = try? Activity.request(attributes: attributes, content: activityContent)
    }

    func update(_ content: AnySSHCore.ActivityContent) async {
        guard let activity = Activity<LiveActivityAttributes>.activities.first,
            activity.attributes.sessionID == content.sessionID.rawValue
        else { return }
        await activity.update(ActivityContent(state: state(from: content), staleDate: content.staleDate))
    }

    func end(_ content: AnySSHCore.ActivityContent) async {
        guard let activity = Activity<LiveActivityAttributes>.activities.first,
            activity.attributes.sessionID == content.sessionID.rawValue
        else { return }
        await activity.end(
            ActivityContent(state: state(from: content), staleDate: content.staleDate),
            dismissalPolicy: .default)
    }

    private func state(from content: AnySSHCore.ActivityContent) -> LiveActivityAttributes.ContentState {
        LiveActivityAttributes.ContentState(
            title: content.title,
            remoteName: content.remoteName,
            transportState: content.transportState,
            agentState: content.agentState,
            uptime: content.uptime,
            notification: content.notification,
            updatedAt: content.updatedAt
        )
    }
}
