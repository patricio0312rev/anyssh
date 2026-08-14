import AnySSHCore
import Foundation

public actor MockRemoteStore: RemoteStore {
    private var list: RemoteList

    public init(remotes: [Remote]) {
        self.list = RemoteList(remotes)
    }

    public init(scenario: String) {
        self.init(remotes: RemoteFixtures.scenario(scenario))
    }

    public func remotes() async throws -> [Remote] {
        list.remotes
    }

    public func save(_ remote: Remote) async throws {
        list.upsert(remote)
    }

    public func delete(_ id: RemoteID) async throws {
        list.remove(id)
    }

    public func reorder(to order: [RemoteID]) async throws {
        list.reorder(to: order)
    }

    public func move(fromOffsets source: IndexSet, toOffset destination: Int) async throws {
        list.move(fromOffsets: source, toOffset: destination)
    }
}
