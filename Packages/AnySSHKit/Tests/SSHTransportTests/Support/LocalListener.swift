import Darwin
import Foundation

@testable import SSHTransport

final class LocalListener: @unchecked Sendable {
    let port: Int

    private let descriptor: Int32
    private let lock = NSLock()
    private let finished = DispatchSemaphore(value: 0)
    private var accepted = [Int32]()
    private var isOpen = true

    init?(host: String) {
        guard let address = try? AddressResolver.resolve(host: host, port: 0).first else {
            return nil
        }
        let socketDescriptor = socket(address.family, SOCK_STREAM, IPPROTO_TCP)
        guard socketDescriptor >= 0 else { return nil }

        var enabled: Int32 = 1
        setsockopt(
            socketDescriptor, SOL_SOCKET, SO_REUSEADDR, &enabled,
            socklen_t(MemoryLayout<Int32>.size))

        let bound = address.withSocketAddress { pointer, length in
            bind(socketDescriptor, pointer, length)
        }
        guard bound == 0, listen(socketDescriptor, 8) == 0,
            let assigned = Self.assignedPort(socketDescriptor)
        else {
            Darwin.close(socketDescriptor)
            return nil
        }
        let flags = fcntl(socketDescriptor, F_GETFL, 0)
        _ = fcntl(socketDescriptor, F_SETFL, flags | O_NONBLOCK)

        descriptor = socketDescriptor
        port = assigned
        acceptInBackground()
    }

    func speak(_ bytes: [UInt8], withinAttempts ceiling: Int = 2000) -> Bool {
        for _ in 0..<ceiling {
            if let client = lock.withLock({ accepted.first }) {
                return bytes.withUnsafeBytes { send(client, $0.baseAddress, $0.count, 0) } == bytes.count
            }
            usleep(500)
        }
        return false
    }

    func close() {
        lock.lock()
        let wasOpen = isOpen
        isOpen = false
        let clients = accepted
        accepted = []
        lock.unlock()

        guard wasOpen else { return }
        finished.wait()
        for client in clients { Darwin.close(client) }
    }

    private func acceptInBackground() {
        let thread = Thread { [self] in
            while lock.withLock({ isOpen }) {
                var poller = pollfd(fd: descriptor, events: Int16(POLLIN), revents: 0)
                guard poll(&poller, 1, 20) >= 0 else { break }
                let client = accept(descriptor, nil, nil)
                guard client >= 0 else { continue }
                let kept = lock.withLock { () -> Bool in
                    guard isOpen else { return false }
                    accepted.append(client)
                    return true
                }
                if !kept { Darwin.close(client) }
            }
            Darwin.close(descriptor)
            finished.signal()
        }
        thread.name = "anyssh.test.listener"
        thread.stackSize = 512 * 1024
        thread.start()
    }

    private static func assignedPort(_ descriptor: Int32) -> Int? {
        var storage = sockaddr_storage()
        var length = socklen_t(MemoryLayout<sockaddr_storage>.size)
        let code = withUnsafeMutablePointer(to: &storage) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { address in
                getsockname(descriptor, address, &length)
            }
        }
        guard code == 0 else { return nil }

        switch Int32(storage.ss_family) {
        case AF_INET6:
            let address = withUnsafePointer(to: &storage) { pointer in
                pointer.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
            }
            return Int(UInt16(bigEndian: address.sin6_port))
        case AF_INET:
            let address = withUnsafePointer(to: &storage) { pointer in
                pointer.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            }
            return Int(UInt16(bigEndian: address.sin_port))
        default:
            return nil
        }
    }
}
