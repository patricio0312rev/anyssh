public struct HostVersion: Hashable, Sendable, Comparable {
    public let rawValue: String
    private let components: [Int]
    private let suffix: String

    public init?(rawValue: String) {
        let scalars = Array(rawValue)
        guard !scalars.isEmpty else { return nil }
        var numbers = [Int]()
        var digits = ""
        var suffix = ""
        var readingSuffix = false

        for scalar in scalars {
            if scalar.isNumber, !readingSuffix {
                digits.append(scalar)
            } else if scalar == ".", !readingSuffix, !digits.isEmpty {
                numbers.append(Int(digits) ?? 0)
                digits.removeAll(keepingCapacity: true)
            } else {
                readingSuffix = true
                suffix.append(scalar)
            }
        }
        guard !digits.isEmpty else { return nil }
        numbers.append(Int(digits) ?? 0)
        guard !numbers.isEmpty else { return nil }
        self.rawValue = rawValue
        self.components = numbers
        self.suffix = suffix
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        if lhs.suffix == rhs.suffix { return false }
        if lhs.suffix.isEmpty { return false }
        if rhs.suffix.isEmpty { return true }
        return lhs.suffix < rhs.suffix
    }
}

public struct ToolReport: Hashable, Sendable {
    public let path: String?
    public let version: String?

    public init(path: String?, version: String?) {
        self.path = path
        self.version = version
    }

    public var isAvailable: Bool { path != nil }

    public var parsedVersion: HostVersion? {
        guard let version else { return nil }
        return HostVersion(rawValue: version)
    }

    public func supports(minimumVersion: String) -> Bool {
        guard isAvailable, let actual = parsedVersion,
            let minimum = HostVersion(rawValue: minimumVersion)
        else { return false }
        return actual >= minimum
    }
}

public struct HerdrReport: Hashable, Sendable {
    public static let supportedProtocolVersion = 19

    public let tool: ToolReport
    public let protocolVersion: Int?

    public init(tool: ToolReport, protocolVersion: Int?) {
        self.tool = tool
        self.protocolVersion = protocolVersion
    }

    public var isProtocolSupported: Bool {
        guard tool.isAvailable, let protocolVersion else { return false }
        return protocolVersion == Self.supportedProtocolVersion
    }
}

public struct HostCapabilities: Hashable, Sendable {
    public let shell: String
    public let platform: String
    public let locale: String
    public let home: String
    public let searchPath: String
    public let model: String?
    public let product: String?
    public let git: ToolReport
    public let tmux: ToolReport
    public let herdr: HerdrReport

    public init(
        shell: String,
        platform: String,
        locale: String,
        home: String,
        searchPath: String,
        model: String? = nil,
        product: String? = nil,
        git: ToolReport,
        tmux: ToolReport,
        herdr: HerdrReport
    ) {
        self.shell = shell
        self.platform = platform
        self.locale = locale
        self.home = home
        self.searchPath = searchPath
        self.model = model
        self.product = product
        self.git = git
        self.tmux = tmux
        self.herdr = herdr
    }

    public var detectedDeviceType: RemoteDeviceType {
        RemoteDeviceDetector.detect(platform: platform, model: model, product: product)
    }

    public var multiplexerErrorState: MuxErrorState? {
        if herdr.tool.isAvailable, !herdr.isProtocolSupported { return .protocolMismatch }
        if !tmux.isAvailable, !herdr.tool.isAvailable { return .absent }
        return nil
    }

    public func supportsGit(minimumVersion: String) -> Bool {
        git.supports(minimumVersion: minimumVersion)
    }
}
