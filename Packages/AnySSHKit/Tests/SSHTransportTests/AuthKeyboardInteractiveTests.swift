import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: AuthEnvironment.isAvailable))
struct AuthKeyboardInteractiveTests {
    private let user = "otpuser"

    @Test func completesTheTwoRoundExchange() async throws {
        let testbed = try #require(AuthEnvironment.testbed)
        let recorder = AuthAnswerRecorder([.answers(["123456"]), .answers(["phone"])])
        recorder.delay = .milliseconds(20)
        let session = try await AuthSupport.opened()

        try await session.authenticate(
            as: user,
            with: .keyboardInteractive,
            answering: recorder.answering
        )

        #expect(await session.isAuthenticated)
        #expect(recorder.rounds.count == 2)
        let prompts = recorder.rounds.flatMap(\.prompts)
        #expect(prompts.map(\.text) == testbed.keyboardInteractiveRounds.map(\.text))
        #expect(prompts.map(\.isEchoed) == testbed.keyboardInteractiveRounds.map(\.isEchoed))
        #expect(recorder.trace == ["enter1", "exit1", "enter2", "exit2"])
        await session.close()
    }

    @Test func cancellingTheFirstRoundIsItsOwnOutcome() async throws {
        let recorder = AuthAnswerRecorder([.cancelled])
        let session = try await AuthSupport.opened()

        let failure = await AuthSupport.failure(of: {
            try await session.authenticate(
                as: user,
                with: .keyboardInteractive,
                answering: recorder.answering
            )
        })

        #expect(failure?.stateID == "auth.keyboardInteractiveCancelled")
        #expect(recorder.rounds.count == 1)
        #expect(await session.isAuthenticated == false)
        #expect(await session.state == .connected)
        await session.close()
    }

    @Test func cancellingTheSecondRoundStopsAfterTheFirstIsAnswered() async throws {
        let recorder = AuthAnswerRecorder([.answers(["123456"]), .cancelled])
        let session = try await AuthSupport.opened()

        let failure = await AuthSupport.failure(of: {
            try await session.authenticate(
                as: user,
                with: .keyboardInteractive,
                answering: recorder.answering
            )
        })

        #expect(failure?.stateID == "auth.keyboardInteractiveCancelled")
        #expect(recorder.rounds.count == 2)
        #expect(await session.isAuthenticated == false)
        await session.close()
    }

    @Test func aWrongCodeIsARejectionRatherThanACancellation() async throws {
        let recorder = AuthAnswerRecorder([.answers(["000000"]), .answers(["phone"])])
        let session = try await AuthSupport.opened()

        let failure = await AuthSupport.failure(of: {
            try await session.authenticate(
                as: user,
                with: .keyboardInteractive,
                answering: recorder.answering
            )
        })

        #expect(failure?.stateID == "auth.keyboardInteractiveRejected")
        #expect(await session.isAuthenticated == false)
        await session.close()
    }

    @Test func offersOnlyKeyboardInteractiveForTheVerificationAccount() async throws {
        let session = try await AuthSupport.opened()
        #expect(try await session.offeredMethods(for: user) == ["keyboard-interactive"])
        await session.close()
    }
}
