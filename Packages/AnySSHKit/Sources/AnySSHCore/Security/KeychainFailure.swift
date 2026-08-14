import Foundation

public struct KeychainFailure: Error, Hashable, Sendable {
    public enum Operation: String, Sendable {
        case add
        case read
        case search
        case update
        case delete
        case accessControl
    }

    public let operation: Operation
    public let status: OSStatus

    public init(_ operation: Operation, _ status: OSStatus) {
        self.operation = operation
        self.status = status
    }
}
