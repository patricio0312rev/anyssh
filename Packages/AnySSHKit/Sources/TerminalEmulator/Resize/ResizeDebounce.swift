import AnySSHCore

public struct ResizeDebounce: Sendable {
    public static let window = Duration.milliseconds(80)

    public enum Outcome: Hashable, Sendable {
        case unchanged
        case scheduled(due: ContinuousClock.Instant)
    }

    private let window: Duration
    private var delivered: TerminalSize?
    private var pending: TerminalSize?
    private var due: ContinuousClock.Instant?

    public init(window: Duration = ResizeDebounce.window, delivered: TerminalSize? = nil) {
        self.window = window
        self.delivered = delivered
    }

    public var deadline: ContinuousClock.Instant? {
        due
    }

    public var pendingSize: TerminalSize? {
        pending
    }

    @discardableResult
    public mutating func record(_ size: TerminalSize, at now: ContinuousClock.Instant) -> Outcome {
        guard !hasSameGrid(size, as: pending ?? delivered) else { return .unchanged }
        pending = size
        let deadline = now.advanced(by: window)
        due = deadline
        return .scheduled(due: deadline)
    }

    public mutating func fire(at now: ContinuousClock.Instant) -> TerminalSize? {
        guard let pending, let due, now >= due else { return nil }
        self.pending = nil
        self.due = nil
        guard !hasSameGrid(pending, as: delivered) else { return nil }
        delivered = pending
        return pending
    }

    private func hasSameGrid(_ size: TerminalSize, as other: TerminalSize?) -> Bool {
        guard let other else { return false }
        return size.columns == other.columns && size.rows == other.rows
    }
}
