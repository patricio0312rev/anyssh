import CSSH

extension SSHSession {
    func exchangeKeys() async throws {
        guard descriptor >= 0 else { throw record(TransportFailure.notConnected) }
        do {
            try startSession()
            let deadline = ContinuousClock.now + configuration.handshakeTimeout
            let code = try await retrying(deadline: deadline) {
                libssh2_session_handshake($0, self.descriptor)
            }
            guard code == 0 else {
                throw TransportFailure.handshakeFailed(code: code, detail: lastErrorMessage())
            }
        } catch {
            throw record(error)
        }
    }

    func startSession() throws {
        try LibSSH2Library.start()
        guard let session = libssh2_session_init_ex(nil, nil, nil, configuration.io?.context) else {
            throw TransportFailure.handshakeFailed(code: LIBSSH2_ERROR_ALLOC)
        }
        handle = session
        libssh2_session_set_blocking(session, 0)
        install(configuration.io, on: session)
        libssh2_keepalive_config(
            session,
            configuration.wantsKeepaliveReply ? 1 : 0,
            UInt32(clamping: configuration.keepaliveInterval.components.seconds)
        )
    }

    private func install(_ callbacks: SSHIOCallbacks?, on session: OpaquePointer) {
        guard let callbacks else { return }
        let receive = unsafeBitCast(callbacks.receive, to: (@convention(c) () -> Void).self)
        let send = unsafeBitCast(callbacks.send, to: (@convention(c) () -> Void).self)
        libssh2_session_callback_set2(session, LIBSSH2_CALLBACK_RECV, receive)
        libssh2_session_callback_set2(session, LIBSSH2_CALLBACK_SEND, send)
    }
}
