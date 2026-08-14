import Darwin
import Foundation

public struct SessionIdentity: Hashable, Sendable {
    public let handleAddress: UInt
    public let descriptor: Int32
    public let localPort: Int?

    public init(handleAddress: UInt, descriptor: Int32, localPort: Int?) {
        self.handleAddress = handleAddress
        self.descriptor = descriptor
        self.localPort = localPort
    }
}

extension SSHSession {
    public var identity: SessionIdentity? {
        guard let handle, descriptor >= 0 else { return nil }
        return SessionIdentity(
            handleAddress: UInt(bitPattern: handle),
            descriptor: descriptor,
            localPort: Self.localPort(of: descriptor)
        )
    }

    private static func localPort(of descriptor: Int32) -> Int? {
        var storage = sockaddr_storage()
        var length = socklen_t(MemoryLayout<sockaddr_storage>.size)
        let answered = withUnsafeMutablePointer(to: &storage) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(descriptor, $0, &length)
            }
        }
        guard answered == 0 else { return nil }
        switch Int32(storage.ss_family) {
        case AF_INET:
            return withUnsafePointer(to: &storage) { pointer in
                pointer.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                    Int(UInt16(bigEndian: $0.pointee.sin_port))
                }
            }
        case AF_INET6:
            return withUnsafePointer(to: &storage) { pointer in
                pointer.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) {
                    Int(UInt16(bigEndian: $0.pointee.sin6_port))
                }
            }
        default:
            return nil
        }
    }
}
