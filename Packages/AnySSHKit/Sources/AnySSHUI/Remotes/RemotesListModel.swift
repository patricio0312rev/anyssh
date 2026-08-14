import AnySSHCore
import Foundation
import Observation

@MainActor
@Observable
public final class RemotesListModel {
    public enum State: Equatable {
        case loading
        case loaded([Remote])
        case failed(String)
    }

    public private(set) var state: State = .loading

    public private(set) var refusal: SecretsErrorState?

    private let store: any RemoteStore
    private let secrets: any SecretStore

    public init(store: any RemoteStore, secrets: any SecretStore) {
        self.store = store
        self.secrets = secrets
    }

    public var remotes: [Remote] {
        guard case .loaded(let remotes) = state else { return [] }
        return remotes
    }

    public var isEmpty: Bool {
        state == .loaded([])
    }

    public func load() async {
        do {
            state = .loaded(try await store.remotes())
        } catch {
            state = .failed(String(describing: error))
        }
    }

    public func save(_ remote: Remote) async {
        await mutate { try await store.save(remote) }
    }

    public func delete(_ id: RemoteID) async {
        do {
            for kind in SecretKind.allCases {
                try await secrets.remove(SecretReference(remoteID: id, kind: kind))
            }
        } catch let error as SecretStoreError {
            refusal = error.state
            return
        } catch {
            refusal = .keychainWriteDenied
            return
        }
        await mutate { try await store.delete(id) }
    }

    public func move(fromOffsets source: IndexSet, toOffset destination: Int) async {
        await mutate { try await store.move(fromOffsets: source, toOffset: destination) }
    }

    public func dismissRefusal() {
        refusal = nil
    }

    private func mutate(_ change: () async throws -> Void) async {
        do {
            try await change()
        } catch {
            state = .failed(String(describing: error))
            return
        }
        await load()
    }
}
