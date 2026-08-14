import AnySSHCore
import Foundation

public struct StatusToast: Identifiable, Sendable {
    public let id: UUID
    public let severity: StatusToastSeverity
    public let title: String
    public let body: String?
    public let accessibilityIdentifier: String?
    public let action: StatusToastAction?
    public let onDismiss: (@MainActor @Sendable () -> Void)?

    public init(
        id: UUID = UUID(),
        severity: StatusToastSeverity,
        title: String,
        body: String? = nil,
        accessibilityIdentifier: String? = nil,
        action: StatusToastAction? = nil,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil
    ) {
        self.id = id
        self.severity = severity
        self.title = title
        self.body = body
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
        self.onDismiss = onDismiss
    }

    public init(
        id: UUID = UUID(),
        severity: StatusToastSeverity = .error,
        state: ErrorState,
        action: StatusToastAction? = nil,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil
    ) {
        let copy = state.copy
        self.init(
            id: id,
            severity: severity,
            title: copy.title,
            body: copy.body,
            accessibilityIdentifier: state.accessibilityIdentifier,
            action: action,
            onDismiss: onDismiss
        )
    }

    public static func from(
        state: ErrorState,
        severity: StatusToastSeverity = .error,
        onRecover: (@MainActor @Sendable () -> Void)? = nil,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil
    ) -> StatusToast {
        let action = onRecover.map { handler in
            StatusToastAction(title: state.copy.recoveryLabel, handler: handler)
        }
        return StatusToast(severity: severity, state: state, action: action, onDismiss: onDismiss)
    }

    public var announcement: String {
        guard let body, !body.isEmpty else { return title }
        return "\(title). \(body)"
    }
}
