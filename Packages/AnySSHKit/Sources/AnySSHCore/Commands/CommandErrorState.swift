public enum CommandErrorState: String, ErrorStateMember {
    case responseUnreadable
    case responseTooLarge
    case programMissing
    case failed
    case signalled

    public static let group = ErrorStateGroup.command

    public var copy: ErrorStateCopy {
        switch self {
        case .responseUnreadable:
            ErrorStateCopy(
                title: "Reply could not be read",
                body: "The host's answer arrived incomplete or out of order, so none of it was "
                    + "used. Run the request again.",
                recoveryLabel: "Try Again"
            )
        case .responseTooLarge:
            ErrorStateCopy(
                title: "Reply too large",
                body: "The host sent more than one request may return, so it was stopped and none "
                    + "of it was used. Run the request again.",
                recoveryLabel: "Try Again"
            )
        case .programMissing:
            ErrorStateCopy(
                title: "Program not found",
                body: "This command is not on the host's login shell PATH. Install it, or add it "
                    + "to that PATH.",
                recoveryLabel: "Check Again"
            )
        case .failed:
            ErrorStateCopy(
                title: "Command failed",
                body: "The command ran on the host and ended with an error. Its own output says "
                    + "why.",
                recoveryLabel: "Dismiss"
            )
        case .signalled:
            ErrorStateCopy(
                title: "Command stopped",
                body: "A signal ended this command on the host before it finished. Run it again.",
                recoveryLabel: "Try Again"
            )
        }
    }

    public var owningPhase: Int { 28 }
}
