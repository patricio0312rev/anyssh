import AnySSHCore
import Foundation

public final class MemoryClipboardPasteboard: ClipboardPasteboard, ClipboardContentSource,
    @unchecked Sendable
{
    private let lock = NSLock()
    private var stored: String?
    private var storedImage: PastedImage?
    public private(set) var writeCount = 0
    public private(set) var readCount = 0
    public private(set) var imageReadCount = 0

    public init(_ value: String? = nil, image: PastedImage? = nil) {
        stored = value
        storedImage = image
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

    public func contentKinds() -> ClipboardContentKinds {
        lock.withLock {
            ClipboardContentKinds(hasText: stored != nil, hasImage: storedImage != nil)
        }
    }

    public func readText() -> String? {
        read()
    }

    public func readImage() -> PastedImage? {
        lock.withLock {
            imageReadCount += 1
            return storedImage
        }
    }
}
