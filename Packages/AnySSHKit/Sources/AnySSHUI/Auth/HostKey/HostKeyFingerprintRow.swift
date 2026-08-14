import SwiftUI

struct HostKeyFingerprintRow: View {
    let label: String
    let fingerprint: String
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step1) {
            Text(label)
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
            Text(fingerprint)
                .font(Theme.code())
                .textSelection(.enabled)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier(identifier)
                .accessibilityLabel(label)
                .accessibilityValue(fingerprint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
