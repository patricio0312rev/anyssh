enum MuxHopDeadline {
    struct Expired: Error, Equatable {}

    static func run<Value: Sendable>(
        within budget: MuxHopBudget,
        _ operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        let first = MuxHopRace<Value>()
        let settled = MuxHopRace<Value>()
        let work = Task {
            let result: Result<Value, any Error>
            do {
                result = .success(try await operation())
            } catch {
                result = .failure(error)
            }
            first.finish(result)
            settled.finish(result)
        }
        let timer = expire(first, after: budget.limit)
        defer { timer.cancel() }
        do {
            return try await first.value()
        } catch is Expired {
            work.cancel()
            return try await drain(settled, within: budget.grace)
        }
    }

    private static func drain<Value: Sendable>(
        _ settled: MuxHopRace<Value>,
        within grace: Duration
    ) async throws -> Value {
        let timer = expire(settled, after: grace)
        defer { timer.cancel() }
        do {
            return try await settled.value()
        } catch {
            throw Expired()
        }
    }

    private static func expire<Value: Sendable>(
        _ race: MuxHopRace<Value>,
        after limit: Duration
    ) -> Task<Void, Never> {
        Task {
            do {
                try await Task.sleep(for: limit)
            } catch {
                return
            }
            race.finish(.failure(Expired()))
        }
    }
}
