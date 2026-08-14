@testable import AnySSHCore

extension KeyFixtures {
    static let rsa4096Plain = KeyFixture(
        name: "RSA 4096 plain",
        text: """
            -----BEGIN OPENSSH PRIVATE KEY-----
            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
            -----END OPENSSH PRIVATE KEY-----
            """,
        format: .openSSH,
        algorithm: .rsa,
        isEncrypted: false,
        bitCount: 4096,
        fingerprint: "SHA256:oUUPHlSJiANy6VSis/WPxU5dIGuqjqhmRYzb4E6n50A"
    )

    static let rsa4096Encrypted = KeyFixture(
        name: "RSA 4096 encrypted",
        text: """
            -----BEGIN OPENSSH PRIVATE KEY-----
            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
            rUyd3+fDPYMMJVd4cirf25wIs=
            -----END OPENSSH PRIVATE KEY-----
            """,
        format: .openSSH,
        algorithm: .rsa,
        isEncrypted: true,
        bitCount: 4096,
        fingerprint: "SHA256:v3FBCETb25DFt4GPH6T6KmhZXQqT087/rA7vc3ggYP8"
    )
}
