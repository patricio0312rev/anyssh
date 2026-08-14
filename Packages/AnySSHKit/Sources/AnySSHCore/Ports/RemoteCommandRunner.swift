public protocol RemoteCommandRunner: Sendable {
    func run(_ batch: RemoteBatch) async throws -> BatchResponse
}
