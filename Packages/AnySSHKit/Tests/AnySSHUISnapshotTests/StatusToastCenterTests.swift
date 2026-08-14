import AnySSHCore
import Foundation
import Testing

@testable import AnySSHUI

@MainActor private final class DismissLog {
    var titles: [String] = []
}

@Suite @MainActor struct StatusToastCenterTests {
    @Test func capacityEvictsTheOldestAndNotifiesIt() {
        let center = StatusToastCenter(capacity: 2)
        let log = DismissLog()
        center.present(
            StatusToast(severity: .success, title: "first") { log.titles.append("first") }
        )
        center.present(severity: .busy, title: "second")
        center.present(severity: .error, title: "third")

        #expect(center.items.map(\.title) == ["second", "third"])
        #expect(log.titles == ["first"])
    }

    @Test func retractDoesNotNotify() {
        let center = StatusToastCenter()
        let log = DismissLog()
        let id = center.present(
            StatusToast(severity: .success, title: "quiet") { log.titles.append("quiet") }
        )
        center.retract(id)

        #expect(center.items.isEmpty)
        #expect(log.titles.isEmpty)
    }

    @Test func dismissAllClearsTheQueue() {
        let center = StatusToastCenter()
        center.present(severity: .success, title: "a")
        center.present(severity: .busy, title: "b")
        center.dismissAll()

        #expect(center.items.isEmpty)
    }

    @Test func errorStateBecomesAToastWithARecoveryAction() {
        let state = ErrorState.transport(.connectionRefused)
        let toast = StatusToast.from(state: state, onRecover: {})

        #expect(toast.title == state.copy.title)
        #expect(toast.action?.title == state.copy.recoveryLabel)
        #expect(toast.accessibilityIdentifier == state.accessibilityIdentifier)
    }

    @Test func dwellRisesWithSeverity() {
        #expect(StatusToastSeverity.success.dwell < StatusToastSeverity.error.dwell)
        for severity in StatusToastSeverity.allCases {
            #expect(severity.dwell > .zero)
        }
    }
}
