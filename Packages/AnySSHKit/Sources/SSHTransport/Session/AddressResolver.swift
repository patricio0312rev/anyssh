import Darwin
import Foundation

public enum AddressResolver {
    public static func addresses(host: String, port: Int) async throws -> [ResolvedAddress] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(with: Result { try resolve(host: host, port: port) })
            }
        }
    }

    public static func resolve(host: String, port: Int) throws -> [ResolvedAddress] {
        let synthesised = query(host: host, port: port, flags: AI_DEFAULT)
        if !synthesised.isEmpty { return synthesised }

        let plain = query(host: host, port: port, flags: 0)
        guard !plain.isEmpty else { throw TransportFailure.resolutionFailed(host: host) }
        return plain
    }

    private static func query(host: String, port: Int, flags: Int32) -> [ResolvedAddress] {
        var hints = addrinfo()
        hints.ai_flags = flags
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM
        hints.ai_protocol = IPPROTO_TCP

        var list: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, String(port), &hints, &list) == 0, let list else { return [] }
        defer { freeaddrinfo(list) }

        var addresses = [ResolvedAddress]()
        var cursor: UnsafeMutablePointer<addrinfo>? = list
        while let entry = cursor {
            if let address = ResolvedAddress(entry.pointee, port: port) { addresses.append(address) }
            cursor = entry.pointee.ai_next
        }
        return addresses
    }
}
