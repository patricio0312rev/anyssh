import AnySSHCore
import CSSH
import Darwin

public struct SSHChannel: @unchecked Sendable {
    static let windowSize = UInt32(2 * 1024 * 1024)
    static let packetSize = UInt32(32 * 1024)

    let pointer: OpaquePointer
    let generation: Int
}

extension SSHSession {
    public func openShell(
        term: String = "xterm-256color",
        size: TerminalSize,
        deadline: ContinuousClock.Instant? = nil
    ) async throws -> SSHChannel {
        let deadline = deadline ?? .now + configuration.handshakeTimeout
        let channel = try await openSessionChannel(deadline: deadline)
        do {
            try await mergeExtendedData(channel, deadline: deadline)
            try await requestPTY(channel, term: term, size: size, deadline: deadline)
            try await startShell(channel, deadline: deadline)
        } catch {
            await closeShell(channel)
            throw error
        }
        noteInboundActivity()
        return channel
    }

    public func resizePTY(
        _ channel: SSHChannel,
        to size: TerminalSize,
        deadline: ContinuousClock.Instant? = nil
    ) async throws {
        try live(channel)
        let code = try await retrying(deadline: deadline ?? .now + configuration.handshakeTimeout) { _ in
            libssh2_channel_request_pty_size_ex(
                channel.pointer,
                Int32(clamping: size.columns),
                Int32(clamping: size.rows),
                Int32(clamping: size.pixelWidth),
                Int32(clamping: size.pixelHeight)
            )
        }
        guard code == 0 else {
            throw TransportFailure.resizeRejected(code: code, detail: lastErrorMessage())
        }
    }

    public func closeShell(_ channel: SSHChannel) async {
        guard isChannelLive(channel) else { return }
        _ = libssh2_channel_close(channel.pointer)
        _ = libssh2_channel_free(channel.pointer)
    }

    public func isChannelLive(_ channel: SSHChannel) -> Bool {
        channel.generation == generation && handle != nil
    }

    func live(_ channel: SSHChannel) throws {
        guard isChannelLive(channel) else { throw TransportFailure.notConnected }
    }

    private func openSessionChannel(deadline: ContinuousClock.Instant) async throws -> SSHChannel {
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
            throw TransportFailure.channelRejected(
                code: LIBSSH2_ERROR_CHANNEL_FAILURE,
                detail: lastErrorMessage()
            )
        }
        return SSHChannel(pointer: opened, generation: generation)
    }

    private func requestPTY(
        _ channel: SSHChannel,
        term: String,
        size: TerminalSize,
        deadline: ContinuousClock.Instant
    ) async throws {
        try live(channel)
        let name = strdup(term)
        let nameLength = UInt32(term.utf8.count)
        defer { free(name) }

        let code = try await retrying(deadline: deadline) { _ in
            libssh2_channel_request_pty_ex(
                channel.pointer,
                name,
                nameLength,
                nil,
                0,
                Int32(clamping: size.columns),
                Int32(clamping: size.rows),
                Int32(clamping: size.pixelWidth),
                Int32(clamping: size.pixelHeight)
            )
        }
        guard code == 0 else {
            throw TransportFailure.ptyRejected(code: code, detail: lastErrorMessage())
        }
    }

    private func startShell(_ channel: SSHChannel, deadline: ContinuousClock.Instant) async throws {
        try live(channel)
        let code = try await retrying(deadline: deadline) { _ in
            libssh2_channel_process_startup(channel.pointer, "shell", UInt32("shell".utf8.count), nil, 0)
        }
        guard code == 0 else {
            throw TransportFailure.shellRejected(code: code, detail: lastErrorMessage())
        }
    }
}
