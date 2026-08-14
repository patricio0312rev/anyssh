public enum AuthMethod: String, CaseIterable, Sendable {
    case publicKey
    case password
    case keyboardInteractive
}

public struct AuthPrompt: Hashable, Sendable {
    public let text: String
    public let isEchoed: Bool

    public init(text: String, isEchoed: Bool) {
        self.text = text
        self.isEchoed = isEchoed
    }
}

public struct AuthPromptRound: Hashable, Sendable {
    public let method: AuthMethod
    public let name: String
    public let instruction: String
    public let prompts: [AuthPrompt]

    public init(method: AuthMethod, name: String, instruction: String, prompts: [AuthPrompt]) {
        self.method = method
        self.name = name
        self.instruction = instruction
        self.prompts = prompts
    }
}

public enum AuthPromptAnswer: Hashable, Sendable {
    case answers([String])
    case cancelled
    case failed(stateID: String)
}
