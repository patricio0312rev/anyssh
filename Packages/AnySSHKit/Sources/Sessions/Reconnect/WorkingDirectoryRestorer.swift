import AnySSHCore
import Foundation

public struct WorkingDirectoryRestorer: Sendable {
    public init() {}

    public func payload(for workspace: WorkspaceLocation?) -> [UInt8]? {
        guard let path = workspace?.path.trimmingCharacters(in: .whitespacesAndNewlines),
            !path.isEmpty,
            path != "~"
        else {
            return nil
        }
        return Array("cd \(Self.command(for: path))\n".utf8)
    }

    static func command(for path: String) -> String {
        guard path == "~" || path.hasPrefix("~/") else {
            return ShellQuoting.singleQuote(path)
        }
        let rest = String(path.dropFirst(2))
        return rest.isEmpty ? "\"$HOME\"" : "\"$HOME\"/" + ShellQuoting.singleQuote(rest)
    }

    public func send(on connection: any RemoteConnection, workspace: WorkspaceLocation?) async throws {
        guard let bytes = payload(for: workspace) else { return }
        try await connection.sendDisplay(bytes[...])
    }
}
