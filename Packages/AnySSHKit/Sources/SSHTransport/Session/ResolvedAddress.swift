import Darwin
import Foundation

public struct ResolvedAddress: Hashable, Sendable {
    public let family: Int32
    public let socketType: Int32
    public let networkProtocol: Int32
    public let literal: String
    public let port: Int

    let bytes: [UInt8]

    public var isIPv6: Bool {
        family == AF_INET6
    }

    public var familyName: String {
        switch family {
        case AF_INET6: "AF_INET6"
        case AF_INET: "AF_INET"
        default: "AF_UNSPEC"
        }
    }

    init?(_ info: addrinfo, port: Int) {
        guard let address = info.ai_addr, info.ai_addrlen > 0 else { return nil }
        let length = Int(info.ai_addrlen)

        family = info.ai_family
        socketType = info.ai_socktype
        networkProtocol = info.ai_protocol
        self.port = port
        bytes = Array(UnsafeRawBufferPointer(start: UnsafeRawPointer(address), count: length))
        literal = Self.numericHost(of: address, length: socklen_t(length))
    }

    func withSocketAddress<T>(_ body: (UnsafePointer<sockaddr>, socklen_t) -> T) -> T? {
        bytes.withUnsafeBytes { raw -> T? in
            guard let base = raw.baseAddress else { return nil }
            return body(base.assumingMemoryBound(to: sockaddr.self), socklen_t(bytes.count))
        }
    }

    private static func numericHost(of address: UnsafePointer<sockaddr>, length: socklen_t) -> String {
        var buffer = [CChar](repeating: 0, count: 1025)
        let code = getnameinfo(
            address, length, &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST)
        guard code == 0 else { return "" }
        return String(cString: buffer)
    }
}
