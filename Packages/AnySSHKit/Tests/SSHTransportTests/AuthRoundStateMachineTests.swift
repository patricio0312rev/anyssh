import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite struct AuthRoundStateMachineTests {
    @Test func answersARoundWithNoPromptsWithoutAsking() async throws {
        let recorder = AuthAnswerRecorder([])
        var conversation = AuthConversation(answering: recorder.answering)

        #expect(try await conversation.answer(Self.round(prompts: [])).isEmpty)
        #expect(recorder.trace.isEmpty)
        #expect(conversation.rounds == 1)
    }

    @Test func answersOneHiddenPrompt() async throws {
        let recorder = AuthAnswerRecorder([.answers(["123456"])])
        var conversation = AuthConversation(answering: recorder.answering)

        let answers = try await conversation.answer(
            Self.round(prompts: [AuthPrompt(text: "Verification code: ", isEchoed: false)])
        )
        #expect(answers == ["123456"])
        #expect(recorder.rounds.first?.prompts.first?.isEchoed == false)
    }

    @Test func answersThreePromptsInOneRound() async throws {
        let prompts = (1...3).map { AuthPrompt(text: "Question \($0): ", isEchoed: false) }
        let recorder = AuthAnswerRecorder([.answers(["a", "b", "c"])])
        var conversation = AuthConversation(answering: recorder.answering)

        #expect(try await conversation.answer(Self.round(prompts: prompts)) == ["a", "b", "c"])
        #expect(recorder.rounds.first?.prompts.count == 3)
    }

    @Test func keepsFourRoundsInOrderAndNeverOverlapsThem() async throws {
        let recorder = AuthAnswerRecorder((1...4).map { .answers(["answer\($0)"]) })
        recorder.delay = .milliseconds(20)
        var conversation = AuthConversation(answering: recorder.answering)

        for index in 1...4 {
            let answers = try await conversation.answer(Self.round(name: "round\(index)"))
            #expect(answers == ["answer\(index)"])
        }
        let expected = (1...4).flatMap { ["enter\($0)", "exit\($0)"] }
        #expect(recorder.trace == expected)
        #expect(conversation.rounds == 4)
    }

    @Test func cancellingRoundTwoIsItsOwnOutcome() async throws {
        let recorder = AuthAnswerRecorder([.answers(["first"]), .cancelled])
        var conversation = AuthConversation(answering: recorder.answering)

        #expect(try await conversation.answer(Self.round()) == ["first"])
        let failure = await AuthSupport.failure(of: { _ = try await conversation.answer(Self.round()) })
        #expect(failure?.stateID == "auth.keyboardInteractiveCancelled")
        #expect(recorder.trace.count == 4)
    }

    @Test func aRoundThatOutlivesItsWindowTimesOut() async throws {
        let recorder = AuthAnswerRecorder([.answers(["late"])])
        recorder.delay = .seconds(3)
        var conversation = AuthConversation(
            roundTimeout: .milliseconds(50),
            answering: recorder.answering
        )

        let failure = await AuthSupport.failure(of: { _ = try await conversation.answer(Self.round()) })
        #expect(failure?.stateID == "auth.keyboardInteractiveTimedOut")
    }

    @Test func answersTheSameRoundAgainAfterARejection() async throws {
        let recorder = AuthAnswerRecorder([.answers(["wrong"]), .answers(["right"])])
        var conversation = AuthConversation(answering: recorder.answering)
        let round = Self.round(name: "Verification")

        #expect(try await conversation.answer(round) == ["wrong"])
        #expect(try await conversation.answer(round) == ["right"])
        #expect(recorder.rounds.map(\.name) == ["Verification", "Verification"])
    }

    @Test func carriesTheEchoFlagOfEveryPromptInAMixedRound() async throws {
        let prompts = [
            AuthPrompt(text: "Verification code: ", isEchoed: false),
            AuthPrompt(text: "Which device answered? ", isEchoed: true),
        ]
        let recorder = AuthAnswerRecorder([.answers(["123456", "phone"])])
        var conversation = AuthConversation(answering: recorder.answering)

        _ = try await conversation.answer(Self.round(prompts: prompts))
        #expect(recorder.rounds.first?.prompts.map(\.isEchoed) == [false, true])
    }

    @Test func refusesAnAnswerListThatDoesNotMatchThePrompts() async throws {
        let prompts = (1...2).map { AuthPrompt(text: "Question \($0): ", isEchoed: false) }
        let recorder = AuthAnswerRecorder([.answers(["only-one"])])
        var conversation = AuthConversation(answering: recorder.answering)

        let failure = await AuthSupport.failure(of: {
            _ = try await conversation.answer(Self.round(prompts: prompts))
        })
        #expect(failure?.stateID == "auth.promptCountMismatch")
    }

    @Test func aFailedRoundKeepsTheStateIdentifierItWasGiven() async throws {
        let recorder = AuthAnswerRecorder([.failed(stateID: "secrets.biometricCancelled")])
        var conversation = AuthConversation(answering: recorder.answering)

        let failure = await AuthSupport.failure(of: { _ = try await conversation.answer(Self.round()) })
        #expect(failure?.stateID == "secrets.biometricCancelled")
    }

    private static func round(
        name: String = "Verification",
        prompts: [AuthPrompt] = [AuthPrompt(text: "Verification code: ", isEchoed: false)]
    ) -> AuthPromptRound {
        AuthPromptRound(
            method: .keyboardInteractive,
            name: name,
            instruction: "Enter the code from your authenticator.",
            prompts: prompts
        )
    }
}
