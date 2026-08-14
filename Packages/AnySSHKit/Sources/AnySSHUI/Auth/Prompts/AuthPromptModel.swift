import AnySSHCore
import Observation
import SSHTransport

@Observable
@MainActor
public final class AuthPromptModel {
    public enum Stage: Equatable {
        case idle
        case asking(AuthPromptRound)
        case refused(AuthErrorState)
    }

    public private(set) var stage: Stage = .idle
    public var answers = [String]()

    public let roundTimeout: Duration

    private var pending: CheckedContinuation<AuthPromptAnswer, Never>?
    private var alarm: Task<Void, Never>?

    public init(roundTimeout: Duration = .seconds(90)) {
        self.roundTimeout = roundTimeout
    }

    public var answering: AuthPromptAnswering {
        { [self] round in await ask(round) }
    }

    public var round: AuthPromptRound? {
        guard case .asking(let round) = stage else { return nil }
        return round
    }

    public func ask(_ round: AuthPromptRound) async -> AuthPromptAnswer {
        await withCheckedContinuation { continuation in
            resume(.cancelled)
            stage = .asking(round)
            answers = Array(repeating: "", count: round.prompts.count)
            pending = continuation
            startAlarm()
        }
    }

    public func submit() {
        let answers = answers
        stage = .idle
        resume(.answers(answers))
    }

    public func cancel() {
        stage = .refused(.keyboardInteractiveCancelled)
        resume(.cancelled)
    }

    public func dismiss() {
        stage = .idle
    }

    private func startAlarm() {
        let timeout = roundTimeout
        alarm = Task { [weak self] in
            try? await Task.sleep(for: timeout)
            guard !Task.isCancelled else { return }
            self?.timeOut()
        }
    }

    private func timeOut() {
        guard case .asking = stage else { return }
        stage = .refused(.keyboardInteractiveTimedOut)
        resume(.failed(stateID: AuthErrorState.keyboardInteractiveTimedOut.stateID))
    }

    private func resume(_ answer: AuthPromptAnswer) {
        alarm?.cancel()
        alarm = nil
        guard let continuation = pending else { return }
        pending = nil
        continuation.resume(returning: answer)
    }
}
