import AnySSHCore
import SwiftUI

struct KeyImportRefusalView: View {
    let refusal: KeyImportRefusal
    let dismiss: () -> Void

    var body: some View {
        let copy = refusal.copy
        return VStack(alignment: .leading, spacing: Theme.Space.step4) {
            VStack(alignment: .leading, spacing: Theme.Space.step2) {
                Text(copy.title)
                    .font(Theme.Text.screenTitle)
                Text(copy.body)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
            }
            .accessibilityElement(children: .combine)

            Button(copy.recoveryLabel, action: dismiss)
                .buttonStyle(.glass)
                .controlSize(.large)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier(refusal.accessibilityIdentifier)
    }
}
