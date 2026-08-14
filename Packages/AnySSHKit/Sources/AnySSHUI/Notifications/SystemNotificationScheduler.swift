#if canImport(UserNotifications)
import AnySSHCore
import Foundation
import UserNotifications

@MainActor
public final class SystemNotificationScheduler: NSObject, NotificationScheduler,
    UNUserNotificationCenterDelegate
{
    private let onTap: (SessionID, MuxPaneID?) -> Void
    private var authorizationRequested = false

    public init(onTap: @escaping (SessionID, MuxPaneID?) -> Void) {
        self.onTap = onTap
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    public func schedule(_ request: JobAlertRequest) async {
        await ensureAuthorized()
        let content = UNMutableNotificationContent()
        content.title = request.alert.title
        content.body = request.alert.body ?? ""
        content.sound = .default
        content.threadIdentifier = request.sessionID.rawValue
        var userInfo: [String: String] = [NotificationTapRouter.sessionIDKey: request.sessionID.rawValue]
        if let paneID = request.paneID { userInfo[NotificationTapRouter.paneIDKey] = paneID.rawValue }
        content.userInfo = userInfo
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let notification = UNNotificationRequest(
            identifier: "anyssh.job.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(notification)
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        guard let id = NotificationTapRouter.sessionID(from: info) else { return }
        onTap(id, NotificationTapRouter.paneID(from: info))
    }

    private func ensureAuthorized() async {
        guard !authorizationRequested else { return }
        authorizationRequested = true
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        )
    }
}
#endif
