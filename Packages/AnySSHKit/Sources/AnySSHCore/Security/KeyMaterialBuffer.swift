import Foundation

public final class KeyMaterialBuffer: CustomStringConvertible, CustomDebugStringConvertible {
    public let count: Int
    public private(set) var isZeroed = false

    private let storage: UnsafeMutableRawBufferPointer

    public init(_ bytes: some Collection<UInt8>) {
        count = bytes.count
        storage = .allocate(byteCount: Swift.max(bytes.count, 1), alignment: 1)
        storage.initializeMemory(as: UInt8.self, repeating: 0)
        storage.copyBytes(from: bytes)
    }

    public convenience init(text: String) {
        self.init(Array(text.utf8))
    }

    deinit {
        storage.initializeMemory(as: UInt8.self, repeating: 0)
        storage.deallocate()
    }

    public func withBytes<T>(_ body: (UnsafeRawBufferPointer) throws -> T) rethrows -> T {
        try body(UnsafeRawBufferPointer(rebasing: storage[0..<count]))
    }

    public func data() -> Data {
        withBytes { Data($0) }
    }

    public func zero() {
        storage.initializeMemory(as: UInt8.self, repeating: 0)
        isZeroed = true
    }

    public var description: String {
        "KeyMaterialBuffer(\(count) bytes, zeroed: \(isZeroed))"
    }

    public var debugDescription: String {
        description
    }
}
