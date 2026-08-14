#if canImport(UIKit)
import SwiftUI
import Testing

@testable import AnySSHUI

@Suite @MainActor struct StatusToastSnapshotTests {
    @Test func everySeverity() {
        ComponentSnapshot.assert(
            VStack(spacing: Theme.Space.step2) {
                ForEach(StatusToastSeverity.allCases, id: \.self) { severity in
                    StatusToastCard(
                        toast: StatusToast(
                            severity: severity,
                            title: severity.rawValue.capitalized,
                            body: "A short sentence describing the outcome."
                        ),
                        onDismiss: {}
                    )
                }
            }
            .padding(Theme.Space.screenMargin),
            named: "severities",
            height: 480
        )
    }

    @Test func cardWithAction() {
        ComponentSnapshot.assert(
            StatusToastCard(
                toast: StatusToast(
                    severity: .error,
                    title: "Connection refused",
                    body: "Nothing is listening on port 22.",
                    action: StatusToastAction(title: "Edit Host") {}
                ),
                onDismiss: {}
            )
            .padding(Theme.Space.screenMargin),
            named: "cardWithAction",
            height: 180
        )
    }

    @Test func hostStacksToasts() {
        let center = StatusToastCenter()
        center.present(severity: .success, title: "Key imported", body: "id_ed25519")
        center.present(severity: .busy, title: "Reconnecting", body: "Attempt 2 of 5")
        ComponentSnapshot.assert(
            StatusToastHost(center: center)
                .frame(maxHeight: .infinity, alignment: .bottom),
            named: "host",
            height: 300
        )
    }
}
#endif
