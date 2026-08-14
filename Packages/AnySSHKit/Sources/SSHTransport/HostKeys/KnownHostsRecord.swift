import AnySSHCore
import Foundation

public struct KnownHostsRecord: Hashable, Sendable {
    public let host: String
    public let port: Int
    public let key: HostKey

    public init(host: String, port: Int, key: HostKey) {
        self.host = host
        self.port = port
        self.key = key
    }

    public static func pattern(host: String, port: Int) -> String {
        port == 22 ? host : "[\(host)]:\(port)"
    }

    public var pattern: String {
        Self.pattern(host: host, port: port)
    }

    public var line: String? {
        guard let name = HostKeyBlob.typeName(of: key.raw) ?? HostKeyBlob.canonicalName(for: key.algorithm),
            !key.raw.isEmpty
        else { return nil }
        return "\(pattern) \(name) \(Data(key.raw).base64EncodedString())"
    }

    public init?(line: String) {
        let fields = line.split(separator: " ", omittingEmptySubsequences: true)
        guard fields.count >= 3, !line.hasPrefix("#"), !line.hasPrefix("@"), !line.hasPrefix("|") else {
            return nil
        }
        guard let target = Self.target(fields[0]),
            let raw = Data(base64Encoded: String(fields[2])), !raw.isEmpty
        else { return nil }

        let name = String(fields[1])
        let key = HostKey(algorithm: HostKeyBlob.algorithm(named: name), raw: Array(raw))
        guard HostKeyBlob.typeName(of: key.raw) == name else { return nil }
        self.init(host: target.host, port: target.port, key: key)
    }

    public func addresses(host: String, port: Int) -> Bool {
        self.port == port && self.host == host
    }

    private static func target(_ field: Substring) -> (host: String, port: Int)? {
        guard field.hasPrefix("[") else {
            return field.contains(where: { $0 == "*" || $0 == "?" || $0 == "," }) ? nil : (String(field), 22)
        }
        guard let close = field.lastIndex(of: "]"), field[field.index(after: close)...].hasPrefix(":"),
            let port = Int(field[field.index(close, offsetBy: 2)...])
        else { return nil }
        let host = String(field[field.index(after: field.startIndex)..<close])
        return host.isEmpty ? nil : (host, port)
    }
}
