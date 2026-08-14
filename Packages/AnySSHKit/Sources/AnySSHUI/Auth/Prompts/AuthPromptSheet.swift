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
            VStack(alignment: .leading, spacing: Theme.Space.step4) {
                if !round.instruction.isEmpty {
                    Text(round.instruction)
                        .font(Theme.Text.body)
                        .accessibilityIdentifier(UIIdentifier.Auth.instruction)
                }
                ForEach(Array(round.prompts.enumerated()), id: \.offset) { index, prompt in
                    AuthPromptField(prompt: prompt, index: index, value: binding(index))
                }
                actions
            }
            .padding()
        }
        .accessibilityIdentifier(UIIdentifier.Auth.sheet)
    }

    private var actions: some View {
        HStack {
            Button("Cancel", role: .cancel, action: model.cancel)
                .accessibilityIdentifier(UIIdentifier.Auth.cancel)
            Spacer()
            Button("Continue", action: model.submit)
                .buttonStyle(.glass)
                .accessibilityIdentifier(UIIdentifier.Auth.submit)
                .keyboardShortcut(.defaultAction)
        }
        .controlSize(.large)
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
