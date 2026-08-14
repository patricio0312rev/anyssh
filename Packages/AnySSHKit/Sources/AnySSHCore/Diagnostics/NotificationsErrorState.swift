public enum NotificationsErrorState: String, ErrorStateMember {
    case jobFailed
    case alertTooLarge
    case alertsSuspended

    public static let group = ErrorStateGroup.notifications

    public var copy: ErrorStateCopy {
        switch self {
        case .jobFailed:
            ErrorStateCopy(
                title: "Job failed",
                body: "A command on the host ended with an error. Open the session to see its output.",
                recoveryLabel: "Open Session"
            )
        case .alertTooLarge:
            ErrorStateCopy(
                title: "Alert dropped",
                body: "The host sent a job alert too large to show. Nothing on the host changed.",
                recoveryLabel: "Dismiss"
            )
        case .alertsSuspended:
            ErrorStateCopy(
                title: "Alerts end when suspended",
                body: "Job alerts arrive while AnySSH is connected or briefly after backgrounding. "
                    + "iOS suspending the app ends them.",
                recoveryLabel: "Got It"
            )
        }
    }

    public var owningPhase: Int { 60 }
}
