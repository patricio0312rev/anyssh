public enum AuthErrorState: String, ErrorStateMember {
    case publicKeyRejected
    case passwordRejected
    case keyboardInteractiveCancelled
    case keyboardInteractiveTimedOut
    case wrongPassphrase

    public static let group = ErrorStateGroup.auth

    public var copy: ErrorStateCopy {
        switch self {
        case .publicKeyRejected:
            ErrorStateCopy(
                title: "Key rejected",
                body: "The host refused this key. Add its public half to authorized_keys on the "
                    + "host, or choose another key.",
                recoveryLabel: "Choose Another Key"
            )
        case .passwordRejected:
            ErrorStateCopy(
                title: "Password rejected",
                body: "The host refused this password. Check the username as well, since a wrong "
                    + "user fails the same way.",
                recoveryLabel: "Try Again"
            )
        case .keyboardInteractiveCancelled:
            ErrorStateCopy(
                title: "Verification cancelled",
                body: "The host asked for a verification code and none was sent. Connect again "
                    + "when you have the code.",
                recoveryLabel: "Connect"
            )
        case .keyboardInteractiveTimedOut:
            ErrorStateCopy(
                title: "Verification timed out",
                body: "The host closed the connection while waiting for the verification code. "
                    + "Connect again and enter it sooner.",
                recoveryLabel: "Connect"
            )
        case .wrongPassphrase:
            ErrorStateCopy(
                title: "Wrong passphrase",
                body: "That passphrase did not decrypt the private key. Enter it again.",
                recoveryLabel: "Try Again"
            )
        }
    }

    public var owningPhase: Int { 11 }
}
