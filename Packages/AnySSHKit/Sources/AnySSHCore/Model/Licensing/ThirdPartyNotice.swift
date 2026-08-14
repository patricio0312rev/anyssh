public struct ThirdPartyNotice: Hashable, Sendable, Identifiable, Comparable {
    public let name: String
    public let licence: String
    public let url: String
    public let resource: String

    public var id: String { resource }

    public init(name: String, licence: String, url: String, resource: String) {
        self.name = name
        self.licence = licence
        self.url = url
        self.resource = resource
    }

    public static func < (lhs: ThirdPartyNotice, rhs: ThirdPartyNotice) -> Bool {
        lhs.name.lowercased() < rhs.name.lowercased()
    }
}
