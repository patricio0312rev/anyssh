import AnySSHCore
import Foundation

public final class MemoryClipboardPasteboard: ClipboardPasteboard, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: String?
    public private(set) var writeCount = 0
    public private(set) var readCount = 0

    public init(_ value: String? = nil) {
        stored = value
    }

    public var value: String? {
        lock.withLock { stored }
    }

    public func write(_ text: String) {
        lock.withLock {
            stored = text
            writeCount += 1
        }
    }

    public func read() -> String? {
        lock.withLock {
            readCount += 1
            return stored
        }
    }
}
