import AnySSHCore

public struct TerminalMetadata: Hashable, Sendable {
    public var title: String?
    public var workingDirectory: String?
    public var state: TransportState?
    public var didRing = false

    public var isEmpty: Bool {
        title == nil && workingDirectory == nil && state == nil && !didRing
    }

    public init() {}
}

public typealias TerminalMetadataDelivery = @MainActor @Sendable (TerminalMetadata) -> Void

@MainActor
public final class TerminalMetadataCoalescer {
    private var pending = TerminalMetadata()

    public init() {}

    public func record(title: String) {
        pending.title = title
    }

    public func record(workingDirectory: String) {
        pending.workingDirectory = workingDirectory
    }

    public func record(state: TransportState) {
        pending.state = state
    }

    public func recordBell() {
        pending.didRing = true
    }

    public func flush() -> TerminalMetadata? {
        guard !pending.isEmpty else { return nil }
        defer { pending = TerminalMetadata() }
        return pending
    }
}
