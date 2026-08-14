import AnySSHCore

public enum ClipboardRefusal: String, Sendable, Hashable {
    case tooLarge = "app.clipboardTooLarge"
    case denied = "app.clipboardDenied"
    case pasteCancelled = "app.pasteCancelled"
    case tmuxClipboardOff = "app.tmuxClipboardOff"

    public var stateID: String { rawValue }

    public var accessibilityIdentifier: String { "error.\(rawValue)" }

    public var copy: ErrorStateCopy {
        switch self {
        case .tooLarge:
            ErrorStateCopy(
                title: "Clipboard payload too large",
                body: "The host sent more than 256 KB of clipboard data, so nothing was copied. "
                    + "Copy a smaller selection on the host.",
                recoveryLabel: "Dismiss"
            )
        case .denied:
            AppErrorState.clipboardDenied.copy
        case .pasteCancelled:
            AppErrorState.pasteCancelled.copy
        case .tmuxClipboardOff:
            ErrorStateCopy(
                title: "tmux clipboard passthrough is off",
                body: "tmux is on this host without clipboard passthrough, so remote copies never "
                    + "reach this device. Add set -g set-clipboard on to your tmux.conf.",
                recoveryLabel: "Dismiss"
            )
        }
    }
}
