import Foundation

public struct MockDisplayStep: Sendable {
    public let delay: Duration
    public let bytes: [UInt8]

    public init(delay: Duration, bytes: [UInt8]) {
        self.delay = delay
        self.bytes = bytes
    }
}

public struct MockDisplayScript: Sendable {
    public let steps: [MockDisplayStep]

    public init(steps: [MockDisplayStep] = []) {
        self.steps = steps
    }
}
