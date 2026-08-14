import Foundation

public struct LinkRow: Equatable, Sendable {
    public let text: String
    public let isWrapped: Bool

    public init(text: String, isWrapped: Bool) {
        self.text = text
        self.isWrapped = isWrapped
    }
}
