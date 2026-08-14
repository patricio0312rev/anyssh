import AnySSHCore
import Foundation

public enum HostKeyFixtures {
    public static let storedBase64 =
        "AAAAC3NzaC1lZDI1NTE5AAAAIEjBBjQguozGFRgPXzA5UTWQu1MZdf4N6ky1pww6xemV"
    public static let offeredBase64 =
        "AAAAC3NzaC1lZDI1NTE5AAAAIEYlInfcqURBkah7sLnjPrtBrZjEtrYQJISKu2W+VsZq"

    public static let stored = key(storedBase64)

    public static let offered = key(offeredBase64)

    public static let host = "mock.local"
    public static let port = 22

    public static func store(_ scenario: ScriptedHostKeyStore.Scenario) -> ScriptedHostKeyStore {
        ScriptedHostKeyStore(scenario: scenario, host: host, port: port)
    }

    public static var scenarios: [String: ScriptedHostKeyStore.Scenario] {
        [
            "unknownHost": .unknownHost,
            "knownAndMatching": .knownAndMatching(stored),
            "knownAndChanged": .knownAndChanged(stored: stored),
        ]
    }

    private static func key(_ base64: String) -> HostKey {
        HostKey(algorithm: .ed25519, raw: Array(Data(base64Encoded: base64) ?? Data()))
    }
}
