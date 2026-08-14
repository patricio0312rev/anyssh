import AnySSHCore
import SwiftUI

struct KeyImportSummary: View {
    let key: KeyMaterial
    let isSaved: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step3) {
            HStack(spacing: Theme.Space.step2) {
                Image(systemName: isSaved ? "checkmark.seal.fill" : "key.fill")
                Text(isSaved ? "Key saved to this device" : "Key read")
                    .font(Theme.Text.sectionHeader)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(
                isSaved ? UIIdentifier.KeyImport.saved : UIIdentifier.KeyImport.headline
            )

            VStack(alignment: .leading, spacing: Theme.Space.step1) {
                Text("Type")
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.secondary)
                Text(description)
                    .font(Theme.Text.body)
                    .accessibilityIdentifier(UIIdentifier.KeyImport.algorithm)
            }

            if let fingerprint = key.fingerprint {
                HostKeyFingerprintRow(
                    label: "Fingerprint",
                    fingerprint: fingerprint,
                    identifier: UIIdentifier.KeyImport.fingerprint
                )
            } else {
                Text(
                    "This format keeps its public half encrypted, so there is no fingerprint to "
                        + "show until the passphrase is entered."
                )
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
                .accessibilityIdentifier(UIIdentifier.KeyImport.fingerprint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var description: String {
        let bits = key.bitCount.map { "\($0)-bit " } ?? ""
        let lock = key.isEncrypted ? ", encrypted" : ""
        return "\(bits)\(key.algorithm.label), \(key.format.label)\(lock)"
    }
}
