public enum TrustErrorState: String, ErrorStateMember {
    case firstUse
    case rejected
    case hostKeyChanged
    case cancelled

    public static let group = ErrorStateGroup.trust

    public var copy: ErrorStateCopy {
        switch self {
        case .firstUse:
            ErrorStateCopy(
                title: "Unknown host",
                body: "This is the first connection to this host. Compare the fingerprint with "
                    + "the one on the host before you accept it.",
                recoveryLabel: "Accept"
            )
        case .rejected:
            ErrorStateCopy(
                title: "Host key rejected",
                body: "The connection closed. Nothing about this host was saved, so the next "
                    + "attempt asks again.",
                recoveryLabel: "Dismiss"
            )
        case .hostKeyChanged:
            ErrorStateCopy(
                title: "Host key changed",
                body: "This host offers a different key from the one recorded. Verify the new "
                    + "fingerprint on the host itself before trusting it.",
                recoveryLabel: "Cancel"
            )
        case .cancelled:
            ErrorStateCopy(
                title: "Trust check cancelled",
                body: "The connection closed without a decision. The next attempt asks again.",
                recoveryLabel: "Try Again"
            )
        }
    }

    public var owningPhase: Int { 10 }
}
