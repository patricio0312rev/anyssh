import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite struct AuthStarvationTests {
    @Test func everyHopOfATwoRoundExchangeRunsOffTheCooperativePool() async throws {
        let channel = PromptChannel(roundBudget: .seconds(30))
        let host = ParkedPrompts(channel: channel, rounds: 2)
        let placement = ThreadPlacement()
        host.start()

        let outcome = await AuthRoundLoop.run(
            AuthConversation(
                roundTimeout: .seconds(20),
                answering: { _ in
                    placement.record("answering")
                    return .answers(["123456"])
                }
            ),
            nextRound: {
                placement.record("nextRound")
                return await channel.nextRound()
            },
            provide: {
                placement.record("provide")
                channel.provide($0)
            },
            finished: {
                placement.record("finished")
                return await channel.finished()
            }
        )

        #expect(outcome.failure == nil)
        #expect(outcome.code == 0)
        #expect(host.answers == [["123456"], ["123456"]])
        #expect(placement.hops.contains("answering"))
        #expect(placement.hops.contains("provide"))
        #expect(placement.hops.contains("finished"))
        #expect(placement.strays.isEmpty, "hops that ran on the cooperative pool")
    }

    @Test func aRoundNobodyAnswersEndsAtItsBudgetInsteadOfParkingForever() async {
        let channel = PromptChannel(roundBudget: .milliseconds(250))
        let host = ParkedPrompts(channel: channel, rounds: 1)
        host.start()

        let outcome = await BoundedRun.run(ceiling: .seconds(10)) {
            _ = await channel.finished()
        }
        #expect(outcome == .finished)
        #expect(host.answers == [[]])
    }
}

private final class ThreadPlacement: @unchecked Sendable {
    private let mutex = NSLock()
    private var recorded = [String: Bool]()

    var hops: Set<String> { mutex.withLock { Set(recorded.keys) } }
    var strays: Set<String> { mutex.withLock { Set(recorded.filter { !$0.value }.keys) } }

    func record(_ hop: String) {
        let ours = DelegateExecutor.isCurrent
        mutex.withLock { recorded[hop] = (recorded[hop] ?? true) && ours }
    }
}

private final class ParkedPrompts: @unchecked Sendable {
    private let channel: PromptChannel
    private let rounds: Int
    private let mutex = NSLock()
    private var recorded = [[String]]()

    init(channel: PromptChannel, rounds: Int) {
        self.channel = channel
        self.rounds = rounds
    }

    var answers: [[String]] { mutex.withLock { recorded } }

    func start() {
        let thread = Thread { [self] in
            for index in 0..<rounds {
                let answers = channel.present(Self.round(index))
                mutex.withLock { recorded.append(answers) }
            }
            channel.complete(0)
        }
        thread.name = "anyssh.test.parked-prompts"
        thread.stackSize = 512 * 1024
        thread.start()
    }

    private static func round(_ index: Int) -> AuthPromptRound {
        AuthPromptRound(
            method: .keyboardInteractive,
            name: "Verification",
            instruction: "Enter the code from your authenticator.",
            prompts: [AuthPrompt(text: "Answer \(index + 1): ", isEchoed: index == 1)]
        )
    }
}
