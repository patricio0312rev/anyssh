import AnySSHCore
import CryptoKit
import Foundation

public struct MockByteProducer: Sendable {
    public struct Configuration: Hashable, Sendable {
        public let bytesPerSecond: Int
        public let chunkSize: Int

        public init(bytesPerSecond: Int, chunkSize: Int = 64 * 1024) {
            self.bytesPerSecond = max(1, bytesPerSecond)
            self.chunkSize = max(1, chunkSize)
        }
    }

    public struct ReplayReport: Equatable, Sendable {
        public let bytesEmitted: Int
        public let sha256: String

        public init(bytesEmitted: Int, sha256: String) {
            self.bytesEmitted = bytesEmitted
            self.sha256 = sha256
        }
    }

    public typealias Wait = @Sendable (Duration) async -> Void

    private let configuration: Configuration
    private let wait: Wait

    public init(configuration: Configuration, wait: @escaping Wait = MockByteProducer.sleep) {
        self.configuration = configuration
        self.wait = wait
    }

    public func replay(_ fixture: [UInt8], to sink: any ByteSink) async -> ReplayReport {
        await replay(fixture, repetitions: 1, to: sink)
    }

    public func replay(
        _ fixture: [UInt8],
        repetitions: Int,
        to sink: any ByteSink
    ) async -> ReplayReport {
        var hasher = SHA256()
        var emitted = 0
        guard !fixture.isEmpty, repetitions > 0 else {
            return ReplayReport(bytesEmitted: 0, sha256: digest(hasher))
        }

        for repetition in 0..<repetitions {
            var offset = 0
            while offset < fixture.count {
                guard !Task.isCancelled else {
                    return ReplayReport(bytesEmitted: emitted, sha256: digest(hasher))
                }
                let end = min(offset + configuration.chunkSize, fixture.count)
                let bytes = fixture[offset..<end]
                await sink.ingest(bytes)
                bytes.withUnsafeBytes { hasher.update(bufferPointer: $0) }
                emitted += bytes.count
                offset = end
                if offset < fixture.count || repetition < repetitions - 1 {
                    await wait(interval(for: bytes.count))
                }
            }
        }
        return ReplayReport(bytesEmitted: emitted, sha256: digest(hasher))
    }

    private func interval(for bytes: Int) -> Duration {
        let wholeSeconds = bytes / configuration.bytesPerSecond
        guard wholeSeconds < Int.max / 1_000_000_000 else { return .nanoseconds(Int64.max) }
        let remainder = bytes % configuration.bytesPerSecond
        let nanos =
            Int64(wholeSeconds) * 1_000_000_000
            + Int64(remainder) * 1_000_000_000 / Int64(configuration.bytesPerSecond)
        return .nanoseconds(max(1, nanos))
    }

    public static func sleep(_ duration: Duration) async {
        guard !Task.isCancelled else { return }
        try? await Task.sleep(for: duration)
    }

    private func digest(_ hasher: SHA256) -> String {
        hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
