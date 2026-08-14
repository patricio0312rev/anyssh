public enum SecretKind: String, CaseIterable, Sendable {
    case password
    case privateKey
    case keyPassphrase
}

public struct SecretReference: Hashable, Sendable {
    public let remoteID: RemoteID
    public let kind: SecretKind

    public init(remoteID: RemoteID, kind: SecretKind) {
        self.remoteID = remoteID
        self.kind = kind
    }
}
