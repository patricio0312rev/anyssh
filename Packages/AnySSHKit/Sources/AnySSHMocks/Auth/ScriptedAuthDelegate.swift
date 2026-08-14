import AnySSHCore
import Foundation

public final class ScriptedAuthDelegate: TerminalTransportDelegate, @unchecked Sendable {
    public struct Script: Hashable, Sendable {
        public var hostKey: HostKeyVerdict
        public var answers: [AuthPromptAnswer]

        public init(hostKey: HostKeyVerdict = .accept(remember: true), answers: [AuthPromptAnswer]) {
            self.hostKey = hostKey
            self.answers = answers
        }

        public static let twoRounds = Script(answers: [.answers(["123456"]), .answers(["phone"])])
        public static let cancelAtFirstRound = Script(answers: [.cancelled])
        public static let cancelAtSecondRound = Script(
            answers: [.answers(["123456"]), .cancelled]
        )
        public static let rejectedThenAccepted = Script(
            answers: [.answers(["000000"]), .answers(["123456"])]
        )
    }

    private let mutex = NSLock()
    private let script: Script
    private var recordedRounds = [AuthPromptRound]()
    private var recordedStates = [TransportState]()

    public init(_ script: Script = .twoRounds) {
        self.script = script
    }

    public var rounds: [AuthPromptRound] {
        mutex.withLock { recordedRounds }
    }

    public var states: [TransportState] {
        mutex.withLock { recordedStates }
    }

    public func transport(
        _ transport: any TerminalTransport,
        verify key: HostKey,
        status: KnownHostStatus
    ) async -> HostKeyVerdict {
        script.hostKey
    }

    public func transport(
        _ transport: any TerminalTransport,
        answer round: AuthPromptRound
    ) async -> AuthPromptAnswer {
        let position = mutex.withLock { () -> Int in
            recordedRounds.append(round)
            return recordedRounds.count - 1
        }
        guard position < script.answers.count else { return .cancelled }
        return script.answers[position]
    }

    public func transport(
        _ transport: any TerminalTransport,
        didChange state: TransportState
    ) async {
        mutex.withLock { recordedStates.append(state) }
    }
}
