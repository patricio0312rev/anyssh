public protocol RecentDirectoriesProbe: Sendable {
    func list(limit: Int) async throws -> [RecentDirectory]
}
