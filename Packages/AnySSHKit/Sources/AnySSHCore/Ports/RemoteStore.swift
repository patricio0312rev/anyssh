import Foundation

public protocol RemoteStore: Sendable {
    func remotes() async throws -> [Remote]

    func save(_ remote: Remote) async throws

    func delete(_ id: RemoteID) async throws

    func reorder(to order: [RemoteID]) async throws

    func move(fromOffsets source: IndexSet, toOffset destination: Int) async throws
}
