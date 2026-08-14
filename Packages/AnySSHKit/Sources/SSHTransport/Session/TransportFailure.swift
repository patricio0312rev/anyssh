import AnySSHCore

public struct TransportFailure: UserFacingError, Hashable {
    public let stateID: String
    public let code: Int32?
    public let detail: String

    public init(stateID: String, code: Int32? = nil, detail: String = "") {
        self.stateID = stateID
        self.code = code
        self.detail = detail
    }

    public static func resolutionFailed(host: String) -> Self {
        Self(stateID: "transport.resolutionFailed", detail: host)
    }

    public static func dialFailed(host: String, code: Int32) -> Self {
        Self(stateID: "transport.dialFailed", code: code, detail: host)
    }

    public static func handshakeFailed(code: Int32, detail: String = "") -> Self {
        Self(stateID: "transport.handshakeFailed", code: code, detail: detail)
    }

    public static func connectionLost(code: Int32) -> Self {
        Self(stateID: "transport.connectionLost", code: code)
    }

    public static let keepaliveTimeout = Self(stateID: "transport.keepaliveTimeout")
    public static let tailscaleSSH = Self(stateID: "transport.tailscaleSSH")
    public static let notConnected = Self(stateID: "transport.notConnected")
}

public struct TransportNote: Hashable, Sendable {
    public let stateID: String
    public let detail: String

    public init(stateID: String, detail: String = "") {
        self.stateID = stateID
        self.detail = detail
    }

    public static func dnsFallback(name: String, address: String) -> Self {
        Self(stateID: "transport.dnsFallback", detail: "\(name) -> \(address)")
    }
}
