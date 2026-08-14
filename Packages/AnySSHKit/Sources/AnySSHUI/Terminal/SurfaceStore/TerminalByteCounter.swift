@MainActor
public final class TerminalByteCounter {
    public private(set) var bytes = 0

    public init() {}

    public func add(_ count: Int) {
        bytes += count
    }
}
