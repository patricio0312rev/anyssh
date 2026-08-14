import AnySSHCore
import Foundation

@testable import SSHTransport

final class AuthAnswerRecorder: @unchecked Sendable {
    private let mutex = NSLock()
    private let plan: [AuthPromptAnswer]
    private var index = 0
    private var recordedTrace = [String]()
    private var recordedRounds = [AuthPromptRound]()

    var delay: Duration = .zero

    init(_ plan: [AuthPromptAnswer]) {
        self.plan = plan
    }

    var trace: [String] { mutex.withLock { recordedTrace } }
    var rounds: [AuthPromptRound] { mutex.withLock { recordedRounds } }

    var answering: AuthPromptAnswering {
        { await self.answer($0) }
    }

    private func answer(_ round: AuthPromptRound) async -> AuthPromptAnswer {
        let position = mutex.withLock { () -> Int in
            index += 1
            recordedRounds.append(round)
            recordedTrace.append("enter\(index)")
            return index
        }
        if delay > .zero { try? await Task.sleep(for: delay) }
        mutex.withLock { recordedTrace.append("exit\(position)") }
        guard position <= plan.count else { return .cancelled }
        return plan[position - 1]
    }
}
