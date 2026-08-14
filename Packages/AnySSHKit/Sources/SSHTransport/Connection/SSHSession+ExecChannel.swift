import AnySSHCore
import CSSH
import Darwin

extension SSHSession {
    func openExec(
        _ command: String,
        deadline: ContinuousClock.Instant
    ) async throws -> SSHChannel {
        let channel = try await openExecChannel(deadline: deadline)
        do {
            try await mergeExtendedData(channel, deadline: deadline)
            try await startExec(channel, command: command, deadline: deadline)
        } catch {
            await release(channel)
            throw error
        }
        noteInboundActivity()
        return channel
    }

    private func openExecChannel(deadline: ContinuousClock.Instant) async throws -> SSHChannel {
        guard handle != nil else { throw TransportFailure.notConnected }
        let generation = self.generation
        var opened: OpaquePointer?
        _ = try await retrying(deadline: deadline) { session in
            opened = libssh2_channel_open_ex(
                session,
                "session",
                UInt32("session".utf8.count),
                SSHChannel.windowSize,
                SSHChannel.packetSize,
                nil,
                0
            )
            guard opened == nil else { return 0 }
            let code = libssh2_session_last_errno(session)
            return code == 0 ? LIBSSH2_ERROR_CHANNEL_FAILURE : code
        }
        guard let opened else {
            throw TransportFailure.execRejected(
                code: LIBSSH2_ERROR_CHANNEL_FAILURE,
                detail: lastErrorMessage()
            )
        }
        return SSHChannel(pointer: opened, generation: generation)
    }

    private func startExec(
        _ channel: SSHChannel,
        command: String,
        deadline: ContinuousClock.Instant
    ) async throws {
        try live(channel)
        let request = strdup(command)
        let length = UInt32(command.utf8.count)
        defer { free(request) }

        let code = try await retrying(deadline: deadline) { _ in
            libssh2_channel_process_startup(
                channel.pointer,
                "exec",
                UInt32("exec".utf8.count),
                request,
                length
            )
        }
        guard code == 0 else {
            throw TransportFailure.execRejected(code: code, detail: lastErrorMessage())
        }
    }
}
