import SwiftUI

public struct CopyableRow: View {
    private let label: String
    private let value: String
    private let monospaced: Bool
    private let displaysValue: Bool
    private let accessibilityIdentifier: String
    private let onCopy: (String) -> Void

    @State private var copied = false

    public init(
        label: String,
        value: String,
        monospaced: Bool = false,
        displaysValue: Bool = true,
        accessibilityIdentifier: String,
        onCopy: @escaping (String) -> Void = { SystemClipboardPasteboard().write($0) }
    ) {
        self.label = label
        self.value = value
        self.monospaced = monospaced
        self.displaysValue = displaysValue
        self.accessibilityIdentifier = accessibilityIdentifier
        self.onCopy = onCopy
    }

    public var body: some View {
        Button(action: copy) {
            HStack(alignment: .center, spacing: Theme.Space.step3) {
                text
                Spacer(minLength: Theme.Space.step2)
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(Theme.Text.body)
                    .foregroundStyle(copied ? Theme.status.online : Theme.text.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Copy \(label)")
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step1) {
            Text(label)
                .font(displaysValue ? Theme.Text.caption : Theme.Text.body)
                .foregroundStyle(displaysValue ? Theme.text.tertiary : Theme.text.primary)
            if displaysValue {
                Text(value)
                    .font(monospaced ? Theme.code() : Theme.Text.body)
                    .foregroundStyle(Theme.text.primary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func copy() {
        onCopy(value)
        withAnimation(Theme.Motion.standard) { copied = true }
        Task {
            try? await Task.sleep(for: Theme.Motion.copyFeedbackDwell)
            withAnimation(Theme.Motion.standard) { copied = false }
        }
    }
}

#Preview("CopyableRow") {
    ThemedRoot {
        SurfaceCard {
            VStack(spacing: Theme.Space.rowGap) {
                CopyableRow(
                    label: "Commit",
                    value: "8f3c1d9a2b4e6f70a1c3d5e7f9012345",
                    monospaced: true,
                    accessibilityIdentifier: "preview.copy.sha"
                ) { _ in }
                CopyableRow(
                    label: "Author",
                    value: "Ada Lovelace",
                    accessibilityIdentifier: "preview.copy.author"
                ) { _ in }
                CopyableRow(
                    label: "Copy snippet",
                    value: "printf '\\033]133;D;%s\\007' \"$?\"",
                    displaysValue: false,
                    accessibilityIdentifier: "preview.copy.snippet"
                ) { _ in }
            }
        }
        .padding(Theme.Space.screenMargin)
    }
}
