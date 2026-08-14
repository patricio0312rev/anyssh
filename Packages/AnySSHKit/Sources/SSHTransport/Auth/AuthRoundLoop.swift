import AnySSHCore

enum AuthRoundLoop {
    struct Outcome: Sendable {
        let code: Int32
        let failure: (any Error)?
    }

    static func run(
        _ conversation: consuming AuthConversation,
        nextRound: @Sendable () async -> AuthPromptRound?,
        provide: @Sendable ([String]) -> Void,
        finished: @Sendable () async -> Int32
    ) async -> Outcome {
        var conversation = conversation
        return await withTaskExecutorPreference(DelegateExecutor.shared) {
            var failure: (any Error)?
            while let round = await nextRound() {
                guard failure == nil else {
                    provide([])
                    continue
                }
                do {
                    provide(try await conversation.answer(round))
                } catch {
                    failure = error
                    provide([])
                }
            }
            return Outcome(code: await finished(), failure: failure)
        }
    }
}
