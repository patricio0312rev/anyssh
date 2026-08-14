import Foundation

public struct JobFinishAlert: Hashable, Sendable {
    public let title: String
    public let body: String?
    public let exitStatus: Int?

    public init(title: String, body: String? = nil, exitStatus: Int? = nil) {
        self.title = title
        self.body = body
        self.exitStatus = exitStatus
    }

    public var isFailure: Bool { (exitStatus ?? 0) != 0 }
}

public struct JobAlertRequest: Hashable, Sendable {
    public let alert: JobFinishAlert
    public let sessionID: SessionID
    public let paneID: MuxPaneID?

    public init(alert: JobFinishAlert, sessionID: SessionID) {
        self.init(alert: alert, sessionID: sessionID, paneID: nil)
    }

    public init(alert: JobFinishAlert, sessionID: SessionID, paneID: MuxPaneID?) {
        self.alert = alert
        self.sessionID = sessionID
        self.paneID = paneID
    }
}

public protocol NotificationScheduler: Sendable {
    func schedule(_ request: JobAlertRequest) async
}
