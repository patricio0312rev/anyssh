import CSSH

public enum TailscaleSSHSignature {
    public static let minimumHang = Duration.seconds(45)

    public static func isTailnetAddress(_ literal: String) -> Bool {
        let parts = literal.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        let octets = parts.compactMap(octet)
        guard octets.count == 4 else { return false }
        return octets[0] == 100 && (64...127).contains(octets[1])
    }

    private static func octet(_ text: Substring) -> Int? {
        guard (1...3).contains(text.count), text.allSatisfy({ $0.isASCII && $0.isNumber }),
            let value = Int(text), value <= 255
        else { return nil }
        return value
    }

    public static func matches(
        elapsed: Duration,
        code: Int32,
        onTailnetAddress: Bool,
        keyConfigurationLooksCorrect: Bool
    ) -> Bool {
        guard onTailnetAddress, keyConfigurationLooksCorrect, elapsed >= minimumHang else {
            return false
        }
        return code == LIBSSH2_ERROR_AUTHENTICATION_FAILED || code == LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED
    }

    public static func classify(
        elapsed: Duration,
        code: Int32,
        onTailnetAddress: Bool,
        keyConfigurationLooksCorrect: Bool
    ) -> TransportFailure? {
        guard
            matches(
                elapsed: elapsed,
                code: code,
                onTailnetAddress: onTailnetAddress,
                keyConfigurationLooksCorrect: keyConfigurationLooksCorrect
            )
        else { return nil }
        return .tailscaleSSH
    }
}
