import Foundation

public final class AppShortcutLog: @unchecked Sendable {
    public static let shared = AppShortcutLog()

    private let lock = NSLock()
    private var events: [AppShortcutEvent] = []

    public init() {}

    public var entries: [AppShortcutEvent] {
        lock.lock()
        defer { lock.unlock() }
        return events
    }

    public var labels: [String] {
        entries.map(\.label)
    }

    public func record(_ event: AppShortcutEvent) {
        lock.lock()
        events.append(event)
        lock.unlock()
    }

    public func clear() {
        lock.lock()
        events.removeAll(keepingCapacity: false)
        lock.unlock()
    }

    public func contains(_ label: String) -> Bool {
        labels.contains(label)
    }
}
