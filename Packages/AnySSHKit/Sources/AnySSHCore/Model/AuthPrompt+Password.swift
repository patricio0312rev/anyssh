extension AuthPromptRound {
    public static func password(username: String) -> AuthPromptRound {
        AuthPromptRound(
            method: .password,
            name: "Password",
            instruction: "Password for \(username)",
            prompts: [AuthPrompt(text: "Password", isEchoed: false)]
        )
    }
}
