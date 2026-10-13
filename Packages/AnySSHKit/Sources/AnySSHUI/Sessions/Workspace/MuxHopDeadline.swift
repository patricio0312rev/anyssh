enum MuxHopDeadline {
    struct Expired: Error, Equatable {}

    static func run<Value: Sendable>(
        within limit: Duration,
        _ operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        let race = MuxHopRace<Value>()
        let work = Task {
            do {
                race.finish(.success(try await operation()))
            } catch {
                race.finish(.failure(error))
            }
        }
        let timer = Task {
            do {
                try await Task.sleep(for: limit)
            } catch {
                return
            }
            race.finish(.failure(Expired()))
        }
        defer {
            work.cancel()
            timer.cancel()
        }
        return try await race.value()
    }
}
