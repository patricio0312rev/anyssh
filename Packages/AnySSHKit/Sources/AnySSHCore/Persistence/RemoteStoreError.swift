public enum RemoteStoreError: UserFacingError, Equatable {
    case unsupportedSchemaVersion(Int)
    case unreadable(String)

    public var stateID: String {
        SecretsErrorState.migrationFailed.stateID
    }
}
