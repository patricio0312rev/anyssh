import AnySSHCore
import SSHTransport

public struct HostKeyPrompt: Equatable, Sendable {
    public let host: String
    public let port: Int
    public let offered: HostKey
    public let status: KnownHostStatus

    public init(host: String, port: Int, offered: HostKey, status: KnownHostStatus) {
        self.host = host
        self.port = port
        self.offered = offered
        self.status = status
    }

    public var state: TrustErrorState {
        isChanged ? .hostKeyChanged : .firstUse
    }

    public var isChanged: Bool {
        if case .changed = status { return true }
        return false
    }

    public var target: String {
        port == 22 ? host : "\(host):\(port)"
    }

    public var algorithmName: String {
        offered.typeName
    }

    public var offeredFingerprint: String {
        offered.fingerprint.openSSH
    }

    public var storedFingerprint: String? {
        guard case .changed(let stored) = status else { return nil }
        return stored.openSSH
    }
}
