import Foundation

public final class ClipboardTransportLog: @unchecked Sendable {
    private let lock = NSLock()
    private var chunks: [[UInt8]] = []

    public init() {}

    public func append(_ chunk: [UInt8]) {
        lock.lock()
        chunks.append(chunk)
        lock.unlock()
    }

    public func snapshot() -> [[UInt8]] {
        lock.lock()
        defer { lock.unlock() }
        return chunks
    }

    public func clear() {
        lock.lock()
        chunks.removeAll(keepingCapacity: true)
        lock.unlock()
    }

    public var joined: [UInt8] {
        snapshot().flatMap { $0 }
    }
}
