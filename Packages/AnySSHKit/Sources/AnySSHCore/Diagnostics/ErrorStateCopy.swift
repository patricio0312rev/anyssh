public struct ErrorStateCopy: Hashable, Sendable {
    public let title: String
    public let body: String
    public let recoveryLabel: String

    public init(title: String, body: String, recoveryLabel: String) {
        self.title = title
        self.body = body
        self.recoveryLabel = recoveryLabel
    }
}
