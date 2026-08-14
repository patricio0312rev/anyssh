import AnySSHCore
import SwiftUI

struct KeyImportSummary: View {
    let key: KeyMaterial
    let isSaved: Bool

    var body: some View {
        Section {
            Label(headline, systemImage: isSaved ? "checkmark.seal.fill" : "key.fill")
                .font(Theme.Text.body)
                .foregroundStyle(isSaved ? Theme.status.online : Theme.text.primary)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(
                    isSaved ? UIIdentifier.KeyImport.saved : UIIdentifier.KeyImport.headline
                )

            VStack(alignment: .leading, spacing: Theme.Space.step1) {
                Text("Type")
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.tertiary)
                Text(description)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.primary)
                    .accessibilityIdentifier(UIIdentifier.KeyImport.algorithm)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let fingerprint = key.fingerprint {
                CopyableRow(
                    label: "Fingerprint",
                    value: fingerprint,
                    monospaced: true,
                    accessibilityIdentifier: UIIdentifier.KeyImport.fingerprint
                )
            }
        } header: {
            SectionLabel("Key")
        } footer: {
            if key.fingerprint == nil {
                Text(
                    "This format keeps its public half encrypted, so there is no fingerprint to "
                        + "show until the passphrase is entered."
                )
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
                .accessibilityIdentifier(UIIdentifier.KeyImport.fingerprint)
            }
        }
        .listRowBackground(Theme.surface.raised)
    }

    private var headline: String {
        isSaved ? "Key saved to this device" : "Key read"
    }

    private var description: String {
        let bits = key.bitCount.map { "\($0)-bit " } ?? ""
        let lock = key.isEncrypted ? ", encrypted" : ""
        return "\(bits)\(key.algorithm.label), \(key.format.label)\(lock)"
    }
}
