public struct RemoteID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct Remote: Identifiable, Hashable, Sendable {
    public let id: RemoteID
    public var name: String
    public var host: String
    public var port: Int
    public var username: String
    public var authMethod: AuthMethod
    public var startPath: String?
    public var startupCommand: String?
    public var tag: String?
    public var orderIndex: Int
    public var deviceType: RemoteDeviceType
    public var deviceTypeSource: RemoteDeviceTypeSource

    public init(
        id: RemoteID,
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        authMethod: AuthMethod = .publicKey,
        startPath: String? = nil,
        startupCommand: String? = nil,
        tag: String? = nil,
        orderIndex: Int = 0,
        deviceType: RemoteDeviceType = .unknown,
        deviceTypeSource: RemoteDeviceTypeSource = .automatic
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.startPath = startPath
        self.startupCommand = startupCommand
        self.tag = tag
        self.orderIndex = orderIndex
        self.deviceType = deviceType
        self.deviceTypeSource = deviceTypeSource
    }

    public var endpoint: String {
        port == 22 ? "\(username)@\(host)" : "\(username)@\(host):\(port)"
    }
}
