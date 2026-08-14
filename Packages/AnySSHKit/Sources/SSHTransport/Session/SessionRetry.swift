import CSSH

extension SSHSession {
    func retrying(
        deadline: ContinuousClock.Instant?,
        _ operation: (OpaquePointer) -> Int32
    ) async throws -> Int32 {
        let generation = self.generation
        while true {
            try Task.checkCancellation()
            let result = operation(try liveHandle(of: generation))
            guard result == LIBSSH2_ERROR_EAGAIN else {
                if result < 0 { diagnostics.errorCodes.append(result) }
                return result
            }
            diagnostics.eagainRetries += 1
            try await waitForSocket(deadline: deadline)
        }
    }

    func liveHandle(of generation: Int) throws -> OpaquePointer {
        guard generation == self.generation, let handle else {
            throw TransportFailure.notConnected
        }
        return handle
    }

    func waitForSocket(deadline: ContinuousClock.Instant?) async throws {
        var directions: Int32 = 0
        if let handle { directions = libssh2_session_block_directions(handle) }
        try await waitForSocket(deadline: deadline, directions: directions)
    }

    func waitForSocket(deadline: ContinuousClock.Instant?, directions: Int32) async throws {
        let now = ContinuousClock.now
        var slice = SSHSession.waitSlice
        if let deadline {
            guard now < deadline else { throw TransportFailure.keepaliveTimeout }
            slice = min(now.duration(to: deadline), slice)
        }

        let readiness = await SessionSocket.waitUntilReady(
            descriptor,
            wantsRead: directions & LIBSSH2_SESSION_BLOCK_INBOUND != 0,
            wantsWrite: directions & LIBSSH2_SESSION_BLOCK_OUTBOUND != 0,
            timeout: slice
        )
        if readiness.readable { noteInboundActivity() }
    }
}
