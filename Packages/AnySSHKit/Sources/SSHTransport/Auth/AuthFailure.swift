import AnySSHCore
import CSSH
import Foundation

public struct AuthFailure: UserFacingError, Hashable {
    public let stateID: String
    public let code: Int32?
    public let detail: String

    public init(stateID: String, code: Int32? = nil, detail: String = "") {
        self.stateID = stateID
        self.code = code
        self.detail = detail
    }

    public static let publicKeyRejected = Self(stateID: "auth.publicKeyRejected")
    public static let passwordRejected = Self(stateID: "auth.passwordRejected")
    public static let wrongPassphrase = Self(stateID: "auth.wrongPassphrase")
    public static let cancelled = Self(stateID: "auth.keyboardInteractiveCancelled")
    public static let timedOut = Self(stateID: "auth.keyboardInteractiveTimedOut")

    public static let promptCountMismatch = Self(stateID: "auth.promptCountMismatch")

    public static let notConnected = Self(stateID: "auth.notConnected")
    public static let noAnswerer = Self(stateID: "auth.noAnswerer")

    public static func methodUnavailable(_ method: AuthMethod, offered: [String]) -> Self {
        Self(stateID: "auth.methodUnavailable", detail: "\(method.rawValue) not in \(offered)")
    }

    static func from(code: Int32, message: String, method: AuthMethod, encrypted: Bool) -> Self {
        let detail = sanitized(message)
        if encrypted, isPassphraseFailure(code: code) {
            return Self(stateID: wrongPassphrase.stateID, code: code, detail: detail)
        }
        switch method {
        case .publicKey:
            return Self(stateID: publicKeyRejected.stateID, code: code, detail: detail)
        case .password:
            return Self(stateID: passwordRejected.stateID, code: code, detail: detail)
        case .keyboardInteractive:
            return Self(stateID: "auth.keyboardInteractiveRejected", code: code, detail: detail)
        }
    }

    private static func isPassphraseFailure(code: Int32) -> Bool {
        code == LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED || code == LIBSSH2_ERROR_FILE
    }

    static let detailLimit = 200

    private static func sanitized(_ message: String) -> String {
        let stripped = message.unicodeScalars
            .filter { !CharacterSet.controlCharacters.contains($0) }
        let trimmed = String(String.UnicodeScalarView(stripped))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(detailLimit))
    }
}
