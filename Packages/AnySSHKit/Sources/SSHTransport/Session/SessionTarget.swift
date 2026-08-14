import AnySSHCore

public struct SessionTarget: Hashable, Sendable {
    public let endpoint: TransportEndpoint
    public let fallbackAddress: String?

    public init(endpoint: TransportEndpoint, fallbackAddress: String? = nil) {
        self.endpoint = endpoint
        self.fallbackAddress = fallbackAddress
    }

    public init(host: String, port: Int = 22, fallbackAddress: String? = nil) {
        self.init(
            endpoint: TransportEndpoint(host: host, port: port),
            fallbackAddress: fallbackAddress
        )
    }

    public init(remote: Remote, fallbackAddress: String? = nil) {
        self.init(endpoint: TransportEndpoint(remote: remote), fallbackAddress: fallbackAddress)
    }

    public var host: String {
        endpoint.host
    }

    public var port: Int {
        endpoint.port
    }
}
