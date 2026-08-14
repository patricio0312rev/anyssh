import AnySSHCore
import Foundation

public struct StartupCommandSender: Sendable {
    public init() {}

    public func payload(from remote: Remote) -> [UInt8]? {
        guard let command = remote.startupCommand?.trimmingCharacters(in: .whitespacesAndNewlines),
            !command.isEmpty
        else {
            return nil
        }
        var bytes = Array(command.utf8)
        if bytes.last != UInt8(ascii: "\n") {
            bytes.append(UInt8(ascii: "\n"))
        }
        return bytes
    }

    public func send(
        on connection: any RemoteConnection,
        remote: Remote
    ) async throws {
        guard let bytes = payload(from: remote) else { return }
        try await connection.sendDisplay(bytes[...])
    }
}
