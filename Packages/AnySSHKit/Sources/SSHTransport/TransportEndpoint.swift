import AnySSHCore

public struct TransportEndpoint: Hashable, Sendable {
    public let host: String
    public let port: Int

    public init(host: String, port: Int = 22) {
        self.host = host
        self.port = port
    }

    public init(remote: Remote) {
        self.init(host: remote.host, port: remote.port)
    }

    public var description: String {
        host.contains(":") ? "[\(host)]:\(port)" : "\(host):\(port)"
    }
}
