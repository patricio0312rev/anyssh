import Darwin
import Foundation

public struct DialResult: Sendable {
    public let descriptor: Int32
    public let address: ResolvedAddress
    public let roundTrip: Duration
}

struct SocketReadiness: Hashable, Sendable {
    var readable = false
    var writable = false

    init(readable: Bool = false, writable: Bool = false) {
        self.readable = readable
        self.writable = writable
    }

    init(revents: Int16) {
        readable = revents & Int16(POLLIN) != 0
        writable = revents & Int16(POLLOUT) != 0
    }
}

enum SessionSocket {
    static func dial(
        _ addresses: [ResolvedAddress],
        host: String,
        timeout: Duration
    ) async throws -> DialResult {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(
                    with: Result { try connect(addresses, host: host, timeout: timeout) })
            }
        }
    }

    static func waitUntilReady(
        _ descriptor: Int32,
        wantsRead: Bool,
        wantsWrite: Bool,
        timeout: Duration
    ) async -> SocketReadiness {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var events = Int16(0)
                if wantsRead || !wantsWrite { events |= Int16(POLLIN) }
                if wantsWrite { events |= Int16(POLLOUT) }
                continuation.resume(returning: waited(descriptor, events, timeout))
            }
        }
    }

    private static func waited(
        _ descriptor: Int32,
        _ events: Int16,
        _ timeout: Duration
    ) -> SocketReadiness {
        let deadline = ContinuousClock.now + timeout
        while true {
            let remaining = ContinuousClock.now.duration(to: deadline)
            guard remaining > .zero else { return SocketReadiness() }
            var descriptors = pollfd(fd: descriptor, events: events, revents: 0)
            let answered = poll(&descriptors, 1, milliseconds(remaining))
            if answered > 0 { return SocketReadiness(revents: descriptors.revents) }
            guard answered < 0, errno == EINTR else { return SocketReadiness() }
        }
    }

    static func close(_ descriptor: Int32) {
        guard descriptor >= 0 else { return }
        _ = Darwin.close(descriptor)
    }

    static func milliseconds(_ duration: Duration) -> Int32 {
        let components = duration.components
        let (scaled, scaleOverflowed) = components.seconds.multipliedReportingOverflow(by: 1000)
        guard !scaleOverflowed else { return components.seconds > 0 ? .max : 0 }
        let (total, sumOverflowed) = scaled.addingReportingOverflow(
            components.attoseconds / 1_000_000_000_000_000
        )
        guard !sumOverflowed else { return scaled > 0 ? .max : 0 }
        let rounded = Int32(clamping: max(0, total))
        return rounded == 0 && duration > .zero ? 1 : rounded
    }

    private static func connect(
        _ addresses: [ResolvedAddress],
        host: String,
        timeout: Duration
    ) throws -> DialResult {
        var lastError: Int32 = ECONNREFUSED
        for address in addresses {
            let start = ContinuousClock.now
            switch attempt(address, timeout: timeout) {
            case .connected(let descriptor):
                return DialResult(
                    descriptor: descriptor,
                    address: address,
                    roundTrip: start.duration(to: .now)
                )
            case .failure(let code):
                lastError = code
            }
        }
        throw TransportFailure.dialFailed(host: host, code: lastError)
    }

    private enum Attempt {
        case connected(Int32)
        case failure(Int32)
    }

    private static func attempt(_ address: ResolvedAddress, timeout: Duration) -> Attempt {
        let descriptor = socket(address.family, address.socketType, address.networkProtocol)
        guard descriptor >= 0 else { return .failure(errno) }

        var enabled: Int32 = 1
        setsockopt(descriptor, IPPROTO_TCP, TCP_NODELAY, &enabled, socklen_t(MemoryLayout<Int32>.size))
        setsockopt(
            descriptor, SOL_SOCKET, SO_NOSIGPIPE, &enabled, socklen_t(MemoryLayout<Int32>.size))

        let flags = fcntl(descriptor, F_GETFL, 0)
        _ = fcntl(descriptor, F_SETFL, flags | O_NONBLOCK)

        let started = address.withSocketAddress { pointer, length in
            Darwin.connect(descriptor, pointer, length)
        }
        guard let started else {
            close(descriptor)
            return .failure(EINVAL)
        }
        if started != 0 {
            let pending = errno
            guard pending == EINPROGRESS else {
                close(descriptor)
                return .failure(pending)
            }
            guard let failure = completion(descriptor, timeout: timeout) else {
                close(descriptor)
                return .failure(ETIMEDOUT)
            }
            guard failure == 0 else {
                close(descriptor)
                return .failure(failure)
            }
        }
        return .connected(descriptor)
    }

    private static func completion(_ descriptor: Int32, timeout: Duration) -> Int32? {
        var descriptors = pollfd(fd: descriptor, events: Int16(POLLOUT), revents: 0)
        guard poll(&descriptors, 1, milliseconds(timeout)) == 1 else { return nil }

        var failure: Int32 = 0
        var size = socklen_t(MemoryLayout<Int32>.size)
        guard getsockopt(descriptor, SOL_SOCKET, SO_ERROR, &failure, &size) == 0 else { return nil }
        return failure
    }
}
