import AnySSHCore
import AnySSHUI
import SwiftUI

struct AuthPromptScenarioView: View {
    @State private var model = AuthPromptModel()

    private let round = AuthPromptRound(
        method: .keyboardInteractive,
        name: "Two-factor authentication",
        instruction: "Enter the code from your authenticator, then the device you are on.",
        prompts: [
            AuthPrompt(text: "Verification code:", isEchoed: false),
            AuthPrompt(text: "Device name:", isEchoed: true),
        ]
    )

    var body: some View {
        Color.clear
            .overlay { AuthPromptSheet(model: model) }
            .task {
                _ = await model.ask(round)
            }
    }
}
