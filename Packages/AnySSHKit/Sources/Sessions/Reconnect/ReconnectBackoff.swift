import Foundation

public struct ReconnectBackoff: Hashable, Sendable {
    public let maxAttempts: Int
    public let baseDelayNanoseconds: UInt64
    public let maxDelayNanoseconds: UInt64

    public static let standard = ReconnectBackoff(
        maxAttempts: 5,
        baseDelay: .milliseconds(500),
        maxDelay: .seconds(16)
    )

    public init(maxAttempts: Int, baseDelay: Duration, maxDelay: Duration) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelayNanoseconds = baseDelay.nanoseconds
        self.maxDelayNanoseconds = max(baseDelay.nanoseconds, maxDelay.nanoseconds)
    }

    public func allows(attempt: Int) -> Bool {
        attempt >= 1 && attempt <= maxAttempts
    }

    public func delay(beforeAttempt attempt: Int) -> Duration {
        guard attempt > 1 else { return .zero }
        var nanos = baseDelayNanoseconds
        for _ in 2..<attempt {
            let doubled = nanos.multipliedReportingOverflow(by: 2)
            if doubled.overflow || doubled.partialValue > maxDelayNanoseconds {
                return .nanoseconds(maxDelayNanoseconds)
            }
            nanos = doubled.partialValue
        }
        return .nanoseconds(min(nanos, maxDelayNanoseconds))
    }

    public func nextAttempt(after current: Int) -> Int? {
        let next = current + 1
        return allows(attempt: next) ? next : nil
    }
}

extension Duration {
    fileprivate var nanoseconds: UInt64 {
        let parts = components
        let seconds = UInt64(max(0, parts.seconds))
        let attoseconds = UInt64(max(0, parts.attoseconds))
        return seconds * 1_000_000_000 + attoseconds / 1_000_000_000
    }
}
