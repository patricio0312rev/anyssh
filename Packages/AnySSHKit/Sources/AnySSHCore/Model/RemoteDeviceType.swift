public enum RemoteDeviceType: String, CaseIterable, Codable, Hashable, Sendable {
    case unknown
    case iPhone
    case iPad
    case laptop
    case desktop
    case macMini
    case macStudio
    case macPro
    case server
    case pc

    public var label: String {
        switch self {
        case .unknown: "Automatic"
        case .iPhone: "iPhone"
        case .iPad: "iPad"
        case .laptop: "Laptop"
        case .desktop: "Desktop"
        case .macMini: "Mac mini"
        case .macStudio: "Mac Studio"
        case .macPro: "Mac Pro"
        case .server: "Server"
        case .pc: "PC"
        }
    }

    public var systemImageName: String {
        switch self {
        case .unknown: "server.rack"
        case .iPhone: "iphone"
        case .iPad: "ipad"
        case .laptop: "laptopcomputer"
        case .desktop: "desktopcomputer"
        case .macMini: "macmini"
        case .macStudio: "macstudio"
        case .macPro: "macpro.gen3"
        case .server: "server.rack"
        case .pc: "pc"
        }
    }
}

public enum RemoteDeviceTypeSource: String, Codable, Hashable, Sendable {
    case automatic
    case user
    case detected
}
