public struct AppCommand: Identifiable {
    public let id: String
    public let title: String
    public let keyEquivalent: AppKeyEquivalent?
    public let isEnabled: () -> Bool
    public let disabledReason: () -> String?
    public let handler: () -> Void

    public init(
        id: String,
        title: String,
        keyEquivalent: AppKeyEquivalent?,
        isEnabled: @escaping () -> Bool,
        disabledReason: @escaping () -> String? = { nil },
        handler: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.keyEquivalent = keyEquivalent
        self.isEnabled = isEnabled
        self.disabledReason = disabledReason
        self.handler = handler
    }
}
