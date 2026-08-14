import SwiftUI

struct StatusToastCard: View {
    let toast: StatusToast
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.step3) {
            Image(systemName: toast.severity.symbolName)
                .font(Theme.Text.body)
                .foregroundStyle(toast.severity.color)
                .accessibilityHidden(true)
            content
            Spacer(minLength: Theme.Space.step2)
            CloseButton(accessibilityIdentifier: UIIdentifier.StatusToast.dismiss, action: onDismiss)
        }
        .padding(Theme.Space.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: shape)
        .overlay { shape.stroke(toast.severity.color.opacity(0.45), lineWidth: 1) }
        .overlay(alignment: .topLeading) {
            ScreenMarker(
                identifier: toast.accessibilityIdentifier
                    ?? UIIdentifier.StatusToast.card(toast.id.uuidString)
            )
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step1) {
            Text(toast.title)
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.primary)
                .fixedSize(horizontal: false, vertical: true)
            if let body = toast.body, !body.isEmpty {
                Text(body)
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let action = toast.action {
                Button(action.title) { action.handler() }
                    .buttonStyle(.plain)
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.accent)
                    .accessibilityIdentifier(
                        action.accessibilityIdentifier ?? UIIdentifier.StatusToast.action
                    )
            }
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.Space.cardRadius, style: .continuous)
    }
}

#Preview("StatusToastCard") {
    ThemedRoot {
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
        .padding(Theme.Space.screenMargin)
    }
}
