import AnySSHCore

public actor RecordingNotificationScheduler: NotificationScheduler {
    public private(set) var requests: [JobAlertRequest] = []

    public init() {}

    public func schedule(_ request: JobAlertRequest) async {
        requests.append(request)
    }
}
