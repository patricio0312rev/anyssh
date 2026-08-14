import Darwin
import Foundation

enum PosixSocket {
    static func connect(host: String, port: Int32, timeout: TimeInterval) -> Int32? {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM

        var list: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, String(port), &hints, &list) == 0 else { return nil }
        defer { freeaddrinfo(list) }

        var candidate = list
        while let info = candidate {
            if let descriptor = dial(info.pointee, timeout: timeout) { return descriptor }
            candidate = info.pointee.ai_next
        }
        return nil
    }

    static func close(_ descriptor: Int32) {
        _ = Darwin.close(descriptor)
    }

    static func isConnected(_ descriptor: Int32, toPort port: Int) -> Bool {
        var storage = sockaddr_storage()
        var length = socklen_t(MemoryLayout<sockaddr_storage>.size)
        let named = withUnsafeMutablePointer(to: &storage) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getpeername(descriptor, $0, &length)
            }
        }
        guard named == 0 else { return false }
        return peerPort(storage) == port
    }

    private static func peerPort(_ storage: sockaddr_storage) -> Int? {
        var storage = storage
        switch Int32(storage.ss_family) {
        case AF_INET6:
            return withUnsafePointer(to: &storage) { pointer in
                pointer.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) {
                    Int(UInt16(bigEndian: $0.pointee.sin6_port))
                }
            }
        case AF_INET:
            return withUnsafePointer(to: &storage) { pointer in
                pointer.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                    Int(UInt16(bigEndian: $0.pointee.sin_port))
                }
            }
        default:
            return nil
        }
    }

    private static func dial(_ info: addrinfo, timeout: TimeInterval) -> Int32? {
        guard let address = info.ai_addr else { return nil }
        let descriptor = socket(info.ai_family, info.ai_socktype, info.ai_protocol)
        guard descriptor >= 0 else { return nil }

        let flags = fcntl(descriptor, F_GETFL, 0)
        _ = fcntl(descriptor, F_SETFL, flags | O_NONBLOCK)

        if Darwin.connect(descriptor, address, info.ai_addrlen) != 0 {
            guard errno == EINPROGRESS, waitForWritable(descriptor, timeout: timeout) else {
                close(descriptor)
                return nil
            }
        }

        _ = fcntl(descriptor, F_SETFL, flags)
        return descriptor
    }

    private static func waitForWritable(_ descriptor: Int32, timeout: TimeInterval) -> Bool {
        var descriptors = pollfd(fd: descriptor, events: Int16(POLLOUT), revents: 0)
        guard poll(&descriptors, 1, Int32(timeout * 1000)) == 1 else { return false }

        var failure: Int32 = 0
        var size = socklen_t(MemoryLayout<Int32>.size)
        guard getsockopt(descriptor, SOL_SOCKET, SO_ERROR, &failure, &size) == 0 else { return false }
        return failure == 0
    }
}
