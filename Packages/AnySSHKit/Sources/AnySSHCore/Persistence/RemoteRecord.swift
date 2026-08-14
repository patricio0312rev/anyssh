enum AuthMethodToken: String, Codable {
    case key
    case pw
    case kbdint

    init(_ method: AuthMethod) {
        switch method {
        case .publicKey: self = .key
        case .password: self = .pw
        case .keyboardInteractive: self = .kbdint
        }
    }

    var method: AuthMethod {
        switch self {
        case .key: .publicKey
        case .pw: .password
        case .kbdint: .keyboardInteractive
        }
    }
}

struct RemoteRecord: Codable, Hashable {
    let id: String
    let name: String
    let host: String
    let port: Int
    let username: String
    let auth: AuthMethodToken
    let startPath: String?
    let startupCommand: String?
    let tag: String?
    let orderIndex: Int
    let deviceType: RemoteDeviceType
    let deviceTypeSource: RemoteDeviceTypeSource

    init(_ remote: Remote) {
        self.id = remote.id.rawValue
        self.name = remote.name
        self.host = remote.host
        self.port = remote.port
        self.username = remote.username
        self.auth = AuthMethodToken(remote.authMethod)
        self.startPath = remote.startPath
        self.startupCommand = remote.startupCommand
        self.tag = remote.tag
        self.orderIndex = remote.orderIndex
        self.deviceType = remote.deviceType
        self.deviceTypeSource = remote.deviceTypeSource
    }

    var remote: Remote {
        Remote(
            id: RemoteID(rawValue: id),
            name: name,
            host: host,
            port: port,
            username: username,
            authMethod: auth.method,
            startPath: startPath,
            startupCommand: startupCommand,
            tag: tag,
            orderIndex: orderIndex,
            deviceType: deviceType,
            deviceTypeSource: deviceTypeSource
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, host, port, username, auth, startPath, startupCommand, tag, orderIndex
        case deviceType, deviceTypeSource
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        host = try values.decode(String.self, forKey: .host)
        port = try values.decode(Int.self, forKey: .port)
        username = try values.decode(String.self, forKey: .username)
        auth = try values.decode(AuthMethodToken.self, forKey: .auth)
        startPath = try values.decodeIfPresent(String.self, forKey: .startPath)
        startupCommand = try values.decodeIfPresent(String.self, forKey: .startupCommand)
        tag = try values.decodeIfPresent(String.self, forKey: .tag)
        orderIndex = try values.decode(Int.self, forKey: .orderIndex)
        deviceType = try values.decodeIfPresent(RemoteDeviceType.self, forKey: .deviceType) ?? .unknown
        deviceTypeSource =
            try values.decodeIfPresent(RemoteDeviceTypeSource.self, forKey: .deviceTypeSource) ?? .automatic
    }
}
