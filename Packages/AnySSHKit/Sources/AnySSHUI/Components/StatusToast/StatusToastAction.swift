import Foundation

public struct StatusToastAction: Sendable, Identifiable {
    public let id: String
    public let title: String
    public let accessibilityIdentifier: String?
    public let handler: @MainActor @Sendable () -> Void

    public init(
        title: String,
        accessibilityIdentifier: String? = nil,
        handler: @escaping @MainActor @Sendable () -> Void
    ) {
        self.id = title
        self.title = title
        self.accessibilityIdentifier = accessibilityIdentifier
        self.handler = handler
    }
}
