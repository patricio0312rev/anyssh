import AnySSHCore

enum RemoteRoute: Identifiable, Hashable {
    case add
    case edit(Remote)
    case importKey

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let remote): "edit.\(remote.id.rawValue)"
        case .importKey: "importKey"
        }
    }

    var remote: Remote? {
        guard case .edit(let remote) = self else { return nil }
        return remote
    }
}
