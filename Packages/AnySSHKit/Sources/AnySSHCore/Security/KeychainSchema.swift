import Foundation

public enum KeychainSchema {
    public static let service = "dev.anyssh.secret"

    public static let markerService = "dev.anyssh.schema"
    public static let markerAccount = "version"

    public static let currentVersion = 1

    public static let unversioned = 0

    private static let stampPrefix = "anyssh/"
    private static let separator: Character = "."

    public static func account(for reference: SecretReference) -> String {
        "\(reference.kind.rawValue)\(separator)\(reference.remoteID.rawValue)"
    }

    public static func reference(fromAccount account: String) -> SecretReference? {
        guard let split = account.firstIndex(of: separator) else { return nil }
        guard let kind = SecretKind(rawValue: String(account[account.startIndex..<split])) else {
            return nil
        }
        let remote = String(account[account.index(after: split)...])
        guard !remote.isEmpty else { return nil }
        return SecretReference(remoteID: RemoteID(rawValue: remote), kind: kind)
    }

    public static func stamp(_ version: Int) -> Data {
        Data("\(stampPrefix)\(version)".utf8)
    }

    public static func version(of stamp: Data?) -> Int {
        guard let stamp, let text = String(data: stamp, encoding: .utf8),
            text.hasPrefix(stampPrefix), let version = Int(text.dropFirst(stampPrefix.count)),
            version >= unversioned
        else { return unversioned }
        return version
    }
}
