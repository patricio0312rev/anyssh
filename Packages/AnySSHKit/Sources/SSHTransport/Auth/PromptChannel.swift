import AnySSHCore
import Foundation

final class PromptChannel: @unchecked Sendable {
    private let roundBudget: Duration
    private let mutex = NSLock()

    private var pending: AuthPromptRound?
    private var waiter: CheckedContinuation<AuthPromptRound?, Never>?
    private var completion: CheckedContinuation<Int32, Never>?
    private var gate: DispatchSemaphore?
    private var answers = [String]()
    private var result: Int32?
    private var isFinished = false

    init(roundBudget: Duration) {
        self.roundBudget = roundBudget
    }

    func nextRound() async -> AuthPromptRound? {
        await withCheckedContinuation { continuation in
            mutex.lock()
            if let round = pending {
                pending = nil
                mutex.unlock()
                continuation.resume(returning: round)
            } else if isFinished {
                mutex.unlock()
                continuation.resume(returning: nil)
            } else {
                waiter = continuation
                mutex.unlock()
            }
        }
    }

    func provide(_ answers: [String]) {
        let gate = mutex.withLock { () -> DispatchSemaphore? in
            self.answers = answers
            return self.gate
        }
        gate?.signal()
    }

    func finished() async -> Int32 {
        await withCheckedContinuation { continuation in
            mutex.lock()
            if let result {
                mutex.unlock()
                continuation.resume(returning: result)
            } else {
                completion = continuation
                mutex.unlock()
            }
        }
    }

    func present(_ round: AuthPromptRound) -> [String] {
        let gate = DispatchSemaphore(value: 0)
        mutex.withLock {
            answers = []
            self.gate = gate
        }
        deliver(round)

        let budget = Int(SessionSocket.milliseconds(roundBudget))
        let arrived = gate.wait(timeout: .now() + .milliseconds(budget)) == .success
        return mutex.withLock {
            self.gate = nil
            return arrived ? answers : []
        }
    }

    func complete(_ code: Int32) {
        mutex.lock()
        result = code
        isFinished = true
        let waiting = waiter
        let finishing = completion
        waiter = nil
        completion = nil
        mutex.unlock()
        waiting?.resume(returning: nil)
        finishing?.resume(returning: code)
    }

    private func deliver(_ round: AuthPromptRound) {
        mutex.lock()
        if let waiting = waiter {
            waiter = nil
            mutex.unlock()
            waiting.resume(returning: round)
        } else {
            pending = round
            mutex.unlock()
        }
    }
}
