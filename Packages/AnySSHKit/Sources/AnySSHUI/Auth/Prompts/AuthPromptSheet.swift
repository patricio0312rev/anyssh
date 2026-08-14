import AnySSHCore
import SwiftUI

public struct AuthPromptSheet: View {
    @Bindable private var model: AuthPromptModel

    public init(model: AuthPromptModel) {
        self.model = model
    }

    public var body: some View {
        switch model.stage {
        case .idle:
            EmptyView()
        case .asking(let round):
            round.prompts.isEmpty ? AnyView(EmptyView()) : AnyView(form(round))
        case .refused(let state):
            AuthPromptRefusalView(state: state, dismiss: model.dismiss)
        }
    }

    private func form(_ round: AuthPromptRound) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.step5) {
                headline(round)
                SurfaceCard {
                    VStack(spacing: Theme.Space.step3) {
                        ForEach(Array(round.prompts.enumerated()), id: \.offset) { index, prompt in
                            AuthPromptField(prompt: prompt, index: index, value: binding(index))
                        }
                    }
                }
                actions
            }
            .padding(Theme.Space.step5)
        }
        .background(Theme.surface.base)
        .accessibilityIdentifier(UIIdentifier.Auth.sheet)
    }

    private func headline(_ round: AuthPromptRound) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.step2) {
            if !round.name.isEmpty {
                Text(round.name)
                    .font(Theme.Text.screenTitle)
                    .foregroundStyle(Theme.text.primary)
            }
            if !round.instruction.isEmpty {
                Text(round.instruction)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
                    .accessibilityIdentifier(UIIdentifier.Auth.instruction)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actions: some View {
        VStack(spacing: Theme.Space.step2) {
            SheetActionButton(
                "Continue",
                emphasis: .primary,
                accessibilityIdentifier: UIIdentifier.Auth.submit,
                action: model.submit
            )
            .keyboardShortcut(.defaultAction)
            SheetActionButton(
                "Cancel",
                accessibilityIdentifier: UIIdentifier.Auth.cancel,
                action: model.cancel
            )
        }
    }

    private func binding(_ index: Int) -> Binding<String> {
        Binding(
            get: { index < model.answers.count ? model.answers[index] : "" },
            set: { value in
                guard index < model.answers.count else { return }
                model.answers[index] = value
            }
        )
    }
}
