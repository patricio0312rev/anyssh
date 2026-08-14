public enum AppErrorState: String, ErrorStateMember {
    case noHostsYet
    case clipboardDenied
    case pasteCancelled

    public static let group = ErrorStateGroup.app

    public var copy: ErrorStateCopy {
        switch self {
        case .noHostsYet:
            ErrorStateCopy(
                title: "No hosts yet",
                body: "Add the host you want to reach, with its address and the user you log in as.",
                recoveryLabel: "Add Host"
            )
        case .clipboardDenied:
            ErrorStateCopy(
                title: "Clipboard access denied",
                body: "iOS refused access to the clipboard. Set Paste from Other Apps to Allow "
                    + "in Settings.",
                recoveryLabel: "Open Settings"
            )
        case .pasteCancelled:
            ErrorStateCopy(
                title: "Paste cancelled",
                body: "Nothing was pasted, and nothing was sent to the host.",
                recoveryLabel: "Paste"
            )
        }
    }

    public var owningPhase: Int {
        switch self {
        case .noHostsYet: 17
        case .clipboardDenied, .pasteCancelled: 26
        }
    }
}
