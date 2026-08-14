import AnySSHCore
import SwiftUI

struct KeyImportRefusalView: View {
    let refusal: KeyImportRefusal
    let dismiss: () -> Void

    var body: some View {
        let copy = refusal.copy
        return Section {
            VStack(alignment: .leading, spacing: Theme.Space.step2) {
                ScreenMarker(identifier: refusal.accessibilityIdentifier)
                Label(copy.title, systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.Text.sectionHeader)
                    .foregroundStyle(Theme.status.attention)
                Text(copy.body)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
            }
            .accessibilityElement(children: .combine)

            Button(copy.recoveryLabel, action: dismiss)
                .buttonStyle(.rowAction)
        }
        .formCardSection()
    }
}
