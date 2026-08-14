import AnySSHCore
import CSSH
import Darwin
import Foundation

extension SSHSession {
    public static let execWaitSlice = Duration.milliseconds(50)

    public static let execCloseSendTimeout = Duration.milliseconds(250)

    public static let execCloseTimeout = Duration.seconds(30)

    public func runExec(
        _ command: String,
        limits: BatchLimits = .default,
        ledger: ControlChannelLedger,
        deadline: ContinuousClock.Instant? = nil
    ) async throws -> Data {
        guard handle != nil else { throw TransportFailure.notConnected }
        let deadline = deadline ?? .now + configuration.handshakeTimeout
        do {
            let channel = try await openExec(command, deadline: deadline)
            let receipt = ledger.opened()
            do {
                let bytes = try await drainExec(channel, limits: limits)
                await closeExec(channel, receipt, in: ledger)
                return bytes
            } catch {
                await closeExec(channel, receipt, in: ledger)
                throw error
            }
        } catch {
            throw error is CancellationError ? TransportFailure.cancelledBySwitch : error
        }
    }

    private func closeExec(
        _ channel: SSHChannel,
        _ receipt: Int,
        in ledger: ControlChannelLedger
    ) async {
        await drainTeardown(channel, deadline: .now + SSHSession.execCloseSendTimeout) {
            libssh2_channel_close(channel.pointer)
        }
        ledger.closed(receipt)
        reap(channel)
    }

    private func reap(_ channel: SSHChannel) {
        Task { await self.release(channel) }
    }

    func release(_ channel: SSHChannel) async {
        let deadline = ContinuousClock.now + SSHSession.execCloseTimeout
        await drainTeardown(channel, deadline: deadline) { libssh2_channel_close(channel.pointer) }
        await drainTeardown(channel, deadline: deadline) { libssh2_channel_free(channel.pointer) }
    }

    private func drainTeardown(
        _ channel: SSHChannel,
        deadline: ContinuousClock.Instant,
        _ operation: () -> Int32
    ) async {
        while isChannelLive(channel) {
            guard operation() == LIBSSH2_ERROR_EAGAIN else { return }
            guard ContinuousClock.now < deadline else { return }
            await waitForExecSocket()
        }
    }

    private func drainExec(_ channel: SSHChannel, limits: BatchLimits) async throws -> Data {
        let buffer = UnsafeMutableRawBufferPointer.allocate(
            byteCount: configuration.readBufferSize,
            alignment: 16
        )
        defer { buffer.deallocate() }
        var collected = Data()

        while true {
            try Task.checkCancellation()
            try live(channel)
            let count = readExec(channel, into: buffer)
            if count > 0 {
                noteInboundActivity()
                guard collected.count + count <= limits.maximumResponseBytes else {
                    throw TransportFailure.controlResponseTooLarge
                }
                collected.append(contentsOf: UnsafeRawBufferPointer(rebasing: buffer[0..<count]))
                continue
            }
            if count == Int(LIBSSH2_ERROR_CHANNEL_CLOSED) { return collected }
            if count == 0, libssh2_channel_eof(channel.pointer) != 0 { return collected }
            guard count == 0 || count == Int(LIBSSH2_ERROR_EAGAIN) else {
                throw TransportFailure.connectionLost(code: Int32(clamping: count))
            }
            await waitForExecSocket()
        }
    }

    private func readExec(_ channel: SSHChannel, into buffer: UnsafeMutableRawBufferPointer) -> Int {
        guard let base = buffer.baseAddress else { return 0 }
        return libssh2_channel_read_ex(
            channel.pointer,
            0,
            base.assumingMemoryBound(to: CChar.self),
            buffer.count
        )
    }

    func waitForExecSocket() async {
        var directions: Int32 = 0
        if let handle { directions = libssh2_session_block_directions(handle) }
        let readiness = await SessionSocket.waitUntilReady(
            descriptor,
            wantsRead: directions & LIBSSH2_SESSION_BLOCK_INBOUND != 0,
            wantsWrite: directions & LIBSSH2_SESSION_BLOCK_OUTBOUND != 0,
            timeout: SSHSession.execWaitSlice
        )
        if readiness.readable { noteInboundActivity() }
    }
}
