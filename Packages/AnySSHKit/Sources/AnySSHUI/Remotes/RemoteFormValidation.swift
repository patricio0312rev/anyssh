import Foundation

enum RemoteFormValidation {
    private static let hostAllowed = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-:_[]%"
    )

    private static let usernameAllowed = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-$\\"
    )

    static let portRange = 1...65535
    static let defaultPort = 22

    static func host(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "Enter the hostname or address of the host."
        }
        if trimmed.contains("://") || trimmed.contains("/") {
            return "Enter a hostname or an address on its own, without a scheme or a path."
        }
        if trimmed.rangeOfCharacter(from: hostAllowed.inverted) != nil {
            return "A hostname can hold letters, digits, dots and hyphens."
        }
        return nil
    }

    static func port(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        guard let port = Int(trimmed), String(port) == trimmed, portRange.contains(port) else {
            return "A port is a whole number from 1 to 65535."
        }
        return nil
    }

    static func resolvedPort(_ value: String) -> Int {
        Int(value.trimmingCharacters(in: .whitespaces)) ?? defaultPort
    }

    static func username(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "Enter the user you log in as on the host."
        }
        if trimmed.count > 32 {
            return "A username on the host is at most 32 characters."
        }
        if trimmed.rangeOfCharacter(from: usernameAllowed.inverted) != nil {
            return "A username can hold letters, digits, dots, hyphens and underscores."
        }
        return nil
    }

    static func password(_ value: String) -> String? {
        value.isEmpty ? "Enter the password for this user." : nil
    }
}
