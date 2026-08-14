import AnySSHCore
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class StatusToastCenter {
    public private(set) var items: [StatusToast] = []

    private var dismissTasks: [UUID: Task<Void, Never>] = [:]
    private let capacity: Int

    public init(capacity: Int = 3) {
        self.capacity = max(1, capacity)
    }

    @discardableResult
    public func present(_ toast: StatusToast) -> UUID {
        if items.count >= capacity, let oldest = items.first {
            remove(id: oldest.id, notify: true)
        }
        items.append(toast)
        scheduleDismiss(for: toast)
        AccessibilityNotification.Announcement(toast.announcement).post()
        return toast.id
    }

    @discardableResult
    public func present(
        severity: StatusToastSeverity,
        title: String,
        body: String? = nil,
        accessibilityIdentifier: String? = nil,
        action: StatusToastAction? = nil,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil
    ) -> UUID {
        present(
            StatusToast(
                severity: severity,
                title: title,
                body: body,
                accessibilityIdentifier: accessibilityIdentifier,
                action: action,
                onDismiss: onDismiss
            )
        )
    }

    @discardableResult
    public func present(
        state: ErrorState,
        severity: StatusToastSeverity = .error,
        onRecover: (@MainActor @Sendable () -> Void)? = nil,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil
    ) -> UUID {
        present(.from(state: state, severity: severity, onRecover: onRecover, onDismiss: onDismiss))
    }

    public func dismiss(_ id: UUID) {
        remove(id: id, notify: true)
    }

    public func retract(_ id: UUID) {
        remove(id: id, notify: false)
    }

    public func dismissAll() {
        for id in items.map(\.id) {
            remove(id: id, notify: true)
        }
    }

    private func scheduleDismiss(for toast: StatusToast) {
        dismissTasks[toast.id]?.cancel()
        let id = toast.id
        let dwell = toast.severity.dwell
        dismissTasks[id] = Task { [weak self] in
            try? await Task.sleep(for: dwell)
            guard !Task.isCancelled else { return }
            self?.remove(id: id, notify: true)
        }
    }

    private func remove(id: UUID, notify: Bool) {
        dismissTasks[id]?.cancel()
        dismissTasks[id] = nil
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let toast = items.remove(at: index)
        if notify {
            toast.onDismiss?()
        }
    }
}
