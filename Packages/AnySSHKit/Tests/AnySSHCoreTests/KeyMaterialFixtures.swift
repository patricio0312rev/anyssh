import Testing

@testable import AnySSHCore

struct KeyFixture {
    let name: String
    let text: String
    let format: PrivateKeyFormat
    let algorithm: PrivateKeyAlgorithm
    let isEncrypted: Bool
    var bitCount: Int?
    var fingerprint: String?

    var expected: KeyMaterial {
        KeyMaterial(
            format: format,
            algorithm: algorithm,
            isEncrypted: isEncrypted,
            bitCount: bitCount,
            fingerprint: fingerprint
        )
    }

    var buffer: KeyMaterialBuffer {
        KeyMaterialBuffer(text: text)
    }
}

extension KeyFixture: CustomTestStringConvertible {
    var testDescription: String {
        name
    }
}

enum KeyFixtures {
    static let passphrase = "fixture-passphrase"

    static let ed25519Plain = KeyFixture(
        name: "ed25519 plain",
        text: """
            -----BEGIN OPENSSH PRIVATE KEY-----
            b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
            QyNTUxOQAAACB91hGzJz3wfCrwzu84DoIXZDMTwGsM5zf97JdB1DWgsQAAAKD1bzeB9W83
            gQAAAAtzc2gtZWQyNTUxOQAAACB91hGzJz3wfCrwzu84DoIXZDMTwGsM5zf97JdB1DWgsQ
            AAAEB0xug+DeAyMRppinmM+cdGLilCmPAcQWwQalrjNTeRTX3WEbMnPfB8KvDO7zgOghdk
            MxPAawznN/3sl0HUNaCxAAAAFmFueXNzaC1maXh0dXJlLWVkMjU1MTkBAgMEBQYH
            -----END OPENSSH PRIVATE KEY-----
            """,
        format: .openSSH,
        algorithm: .ed25519,
        isEncrypted: false,
        bitCount: 256,
        fingerprint: "SHA256:d782vb7ga7XQMt9FSTQ9iN87Acjw/j3rpexf5QaN7sE"
    )

    static let ed25519Encrypted = KeyFixture(
        name: "ed25519 encrypted",
        text: """
            -----BEGIN OPENSSH PRIVATE KEY-----
            b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABAQXBh6hP
            XmY01lI4Ww9S9GAAAAGAAAAAEAAAAzAAAAC3NzaC1lZDI1NTE5AAAAICQnXLS30SM0vgm8
            AloOgjMBZWEGCd7uvBuvkGH3WZS9AAAAoB50mrUpTtkdIYfsXjTencT08pWk3eFUObzBgZ
            Zqb+Dx8M9WUjidSTidDjXCTC9VWC3DTOrOdAYHt9NIJ0IbtzyPJoS20/pAKhhjyhqrn87V
            MaT5pjzApfgTk00CgIgRA/ff3axs/V8XWeO64BZIwuwLEY80Rh2U3qCkGwNvqTQ5Yz84E3
            QPJ8gwAdBeadQ5q9nC3t7AnJ1Frt5GiKzGJyo=
            -----END OPENSSH PRIVATE KEY-----
            """,
        format: .openSSH,
        algorithm: .ed25519,
        isEncrypted: true,
        bitCount: 256,
        fingerprint: "SHA256:Re1NAA/7bCn9RG/pi0EFv8PT1a8TK3mbAe9O2GJ2vlo"
    )

    static let publicKey = """
            ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH3WEbMnPfB8KvDO7zgOghdkMxPAawznN/3sl0HUNaCx anyssh-fixture-ed25519
        """

    static let truncatedWithoutEndLine = """
            -----BEGIN OPENSSH PRIVATE KEY-----
            b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
            QyNTUxOQAAACB91hGzJz3wfCrwzu84DoIXZDMTwGsM5zf97JdB1DWgsQAAAKD1bzeB9W83
            gQAAAAtzc2gtZWQyNTUxOQAAACB91hGzJz3wfCrwzu84DoIXZDMTwGsM5zf97JdB1DWgsQ
        """

    static let truncatedBody = """
            -----BEGIN OPENSSH PRIVATE KEY-----
            b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAA==
            -----END OPENSSH PRIVATE KEY-----
        """

    static let unreadableBody = """
            -----BEGIN OPENSSH PRIVATE KEY-----
            b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
            QyNTUxOQAAACB91hGzJz3wfCrwzu84DoIXZDMTwGsM5zf97JdB1DWgsQAAAKD1bzeB9W83
            gQAAAAtzc2gtZWQyNTUxOQAAACB91hGzJz3wfCrwzu84DoIXZDMTwGsM5zf97JdB1DWgsQ
            -----END OPENSSH PRIVATE KEY-----
        """

    static let all: [KeyFixture] = [
        ed25519Plain, ed25519Encrypted, rsa4096Plain, rsa4096Encrypted, rsaPEM, rsaPEMEncrypted,
        rsaPKCS8, rsaPKCS8Encrypted, ed25519PKCS8,
    ]
}
