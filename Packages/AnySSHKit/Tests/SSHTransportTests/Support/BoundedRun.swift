import Foundation

@testable import SSHTransport

enum BoundedRun {
    enum Outcome: Sendable, Equatable {
        case finished
        case failed(TransportFailure)
        case failedWithOtherError(String)
        case exceededCeiling
    }

    static func run(
        ceiling: Duration,
        _ body: @escaping @Sendable () async throws -> Void
    ) async -> Outcome {
        let first = FirstOutcome()
        let work = Task {
            do {
                try await body()
                await first.settle(.finished)
            } catch let failure as TransportFailure {
                await first.settle(.failed(failure))
            } catch {
                await first.settle(.failedWithOtherError("\(error)"))
            }
        }
        let ceilingTask = Task {
            try? await Task.sleep(for: ceiling)
            await first.settle(.exceededCeiling)
        }

        let outcome = await first.value
        work.cancel()
        ceilingTask.cancel()
        return outcome
    }
}

private actor FirstOutcome {
    private var settled: BoundedRun.Outcome?
    private var waiting: CheckedContinuation<BoundedRun.Outcome, Never>?

    var value: BoundedRun.Outcome {
        get async {
            if let settled { return settled }
            return await withCheckedContinuation { waiting = $0 }
        }
    }

    func settle(_ outcome: BoundedRun.Outcome) {
        guard settled == nil else { return }
        settled = outcome
        waiting?.resume(returning: outcome)
        waiting = nil
    }
}
