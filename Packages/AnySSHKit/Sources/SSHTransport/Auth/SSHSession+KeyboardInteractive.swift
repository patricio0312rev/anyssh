import AnySSHCore
import CSSH
import Foundation

extension SSHSession {
    func attemptKeyboardInteractive(
        username: String,
        answering: @escaping AuthPromptAnswering,
        roundTimeout: Duration
    ) async throws {
        guard let session = handle else { throw AuthFailure.notConnected }
        let ceiling = Self.ceiling(for: roundTimeout)
        let exchange = KeyboardInteractiveExchange(
            session: session,
            username: username,
            roundBudget: .milliseconds(ceiling)
        )
        let context = Unmanaged.passRetained(exchange)
        let slot = libssh2_session_abstract(session)
        let previousContext = slot?.pointee
        let previousTimeout = libssh2_session_get_timeout(session)

        slot?.pointee = context.toOpaque()
        libssh2_session_set_blocking(session, 1)
        libssh2_session_set_timeout(session, ceiling)
        defer {
            libssh2_session_set_timeout(session, previousTimeout)
            libssh2_session_set_blocking(session, 0)
            slot?.pointee = previousContext
            context.release()
        }

        exchange.start()
        let channel = exchange.channel
        let outcome = await AuthRoundLoop.run(
            AuthConversation(roundTimeout: roundTimeout, answering: answering),
            nextRound: { await channel.nextRound() },
            provide: { channel.provide($0) },
            finished: { await channel.finished() }
        )

        if let failure = outcome.failure { throw failure }
        guard outcome.code != 0 else { return }
        throw AuthFailure.from(
            code: outcome.code,
            message: lastErrorMessage(),
            method: .keyboardInteractive,
            encrypted: false
        )
    }

    private static func ceiling(for roundTimeout: Duration) -> Int {
        let milliseconds = roundTimeout.components.seconds * 1000 + 60_000
        return Int(min(max(milliseconds * 4, 60_000), 3_600_000))
    }
}
