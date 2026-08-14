import Foundation

public struct SystemClock: Clock {
    public init() {}
    public var now: Date { Date() }
}
