import AnySSHCore
import Foundation

actor GatedDisplayWriter: DisplayWriter {
    enum Failure: Error {
        case neverSatisfied
    }

    private(set) var writes = [[UInt8]]()
    private var continuation: CheckedContinuation<Void, Never>?
    private var isReleased = false

    func send(_ bytes: ArraySlice<UInt8>) async throws {
        writes.append(Array(bytes))
        guard !isReleased else { return }
        await withCheckedContinuation { self.continuation = $0 }
    }

    func release() {
        isReleased = true
        continuation?.resume()
        continuation = nil
    }

    var hasWritten: Bool { !writes.isEmpty }
}

@MainActor
func waitUntil(attempts: Int = 500, _ condition: () async -> Bool) async throws {
    for _ in 0..<attempts {
        if await condition() { return }
        await Task.yield()
    }
    throw GatedDisplayWriter.Failure.neverSatisfied
}
