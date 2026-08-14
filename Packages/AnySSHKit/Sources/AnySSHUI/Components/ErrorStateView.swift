import AnySSHCore
import SwiftUI

public struct ErrorStateView: View {
    private let state: ErrorState
    private let recover: (() -> Void)?
    private let dismiss: (() -> Void)?

    public init(
        state: ErrorState,
        recover: (() -> Void)? = nil,
        dismiss: (() -> Void)? = nil
    ) {
        self.state = state
        self.recover = recover
        self.dismiss = dismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step5) {
            ScreenMarker(state: state)
            copy
            actions
        }
        .padding(Theme.Space.step5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.surface.base)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step2) {
            Text(state.copy.title)
                .font(Theme.Text.screenTitle)
                .foregroundStyle(Theme.text.primary)
            Text(state.copy.body)
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var actions: some View {
        if recover != nil || dismiss != nil {
            VStack(spacing: Theme.Space.step3) {
                if let recover {
                    Button(action: recover) { label(state.copy.recoveryLabel) }
                        .buttonStyle(.accentCapsule)
                        .accessibilityIdentifier("\(state.accessibilityIdentifier).recover")
                }
                if let dismiss {
                    Button(action: dismiss) { label("Dismiss") }
                        .buttonStyle(.raised)
                        .accessibilityIdentifier("\(state.accessibilityIdentifier).dismiss")
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func label(_ title: String) -> some View {
        Text(title)
            .font(Theme.Text.body)
            .frame(minWidth: Theme.Buttons.minWidth)
    }
}

#Preview("ErrorStateView") {
    ThemedRoot {
        ErrorStateView(state: .transport(.connectionRefused), recover: {}, dismiss: {})
    }
}
