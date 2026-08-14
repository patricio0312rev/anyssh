public enum LinkErrorState: String, ErrorStateMember {
    case schemeRefused

    public static let group = ErrorStateGroup.link

    public var copy: ErrorStateCopy {
        switch self {
        case .schemeRefused:
            ErrorStateCopy(
                title: "Scheme refused",
                body: "This address uses a scheme the app does not open. Copy the address and "
                    + "open it in another app.",
                recoveryLabel: "Copy Address"
            )
        }
    }

    public var owningPhase: Int { 49 }
}
