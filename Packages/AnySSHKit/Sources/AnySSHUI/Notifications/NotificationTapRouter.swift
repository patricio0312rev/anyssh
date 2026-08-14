import AnySSHCore
import Foundation

public enum NotificationTapRouter {
    public nonisolated static let sessionIDKey = "anyssh.sessionID"
    public nonisolated static let paneIDKey = "anyssh.paneID"

    public nonisolated static func sessionID(from userInfo: [AnyHashable: Any]) -> SessionID? {
        guard let raw = userInfo[sessionIDKey] as? String else { return nil }
        return SessionID(rawValue: raw)
    }

    public nonisolated static func paneID(from userInfo: [AnyHashable: Any]) -> MuxPaneID? {
        guard let raw = userInfo[paneIDKey] as? String else { return nil }
        return MuxPaneID(rawValue: raw)
    }
}
