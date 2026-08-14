import AnySSHCore

public typealias AuthPromptAnswering = @Sendable (AuthPromptRound) async -> AuthPromptAnswer

public struct AuthConversation: Sendable {
    public let answering: AuthPromptAnswering
    public let roundTimeout: Duration

    public private(set) var rounds = 0

    public init(roundTimeout: Duration = .seconds(120), answering: @escaping AuthPromptAnswering) {
        self.roundTimeout = roundTimeout
        self.answering = answering
    }

    public mutating func answer(_ round: AuthPromptRound) async throws -> [String] {
        rounds += 1
        guard !round.prompts.isEmpty else { return [] }

        switch await race(round) {
        case .answers(let answers):
            guard answers.count == round.prompts.count else {
                throw AuthFailure(
                    stateID: AuthFailure.promptCountMismatch.stateID,
                    detail: "\(answers.count) answers for \(round.prompts.count) prompts"
                )
            }
            return answers
        case .cancelled:
            throw AuthFailure.cancelled
        case .failed(let stateID):
            throw AuthFailure(stateID: stateID)
        case nil:
            throw AuthFailure.timedOut
        }
    }

    private func race(_ round: AuthPromptRound) async -> AuthPromptAnswer? {
        let relay = AnswerRelay()
        let answering = answering
        let timeout = roundTimeout
        let question = Task(executorPreference: DelegateExecutor.shared) {
            await relay.settle(await answering(round))
        }
        let alarm = Task(executorPreference: DelegateExecutor.shared) {
            try? await Task.sleep(for: timeout)
            await relay.settle(nil)
        }
        defer {
            question.cancel()
            alarm.cancel()
        }
        return await relay.settled
    }
}

private actor AnswerRelay {
    private var outcome: AuthPromptAnswer??
    private var waiter: CheckedContinuation<AuthPromptAnswer?, Never>?

    var settled: AuthPromptAnswer? {
        get async {
            if let outcome { return outcome }
            return await withCheckedContinuation { waiter = $0 }
        }
    }

    func settle(_ answer: AuthPromptAnswer?) {
        guard outcome == nil else { return }
        outcome = .some(answer)
        waiter?.resume(returning: answer)
        waiter = nil
    }
}
