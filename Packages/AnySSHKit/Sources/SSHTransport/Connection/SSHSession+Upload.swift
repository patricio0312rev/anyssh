import AnySSHCore
import CSSH
import Foundation

extension SSHSession {
    func uploadFile(
        _ file: URL,
        command: String,
        ledger: ControlChannelLedger
    ) async throws {
        let channel = try await openExec(command, deadline: .now + configuration.handshakeTimeout)
        let receipt = ledger.opened()
        do {
            let handle = try FileHandle(forReadingFrom: file)
            defer { try? handle.close() }
            while true {
                try Task.checkCancellation()
                guard let data = try handle.read(upToCount: configuration.readBufferSize), !data.isEmpty
                else {
                    break
                }
                let bytes = [UInt8](data)
                try await writeShell(channel, bytes[...])
            }
            try await sendEOF(channel)
            await release(channel)
            ledger.closed(receipt)
        } catch {
            await release(channel)
            ledger.closed(receipt)
            throw error is CancellationError ? TransportFailure.cancelledBySwitch : error
        }
    }

    private func sendEOF(_ channel: SSHChannel) async throws {
        try live(channel)
        let deadline = ContinuousClock.now + SSHSession.execCloseSendTimeout
        while true {
            try Task.checkCancellation()
            let result = libssh2_channel_send_eof(channel.pointer)
            if result == 0 { return }
            guard result == LIBSSH2_ERROR_EAGAIN, ContinuousClock.now < deadline else {
                throw TransportFailure.connectionLost(code: result)
            }
            await waitForExecSocket()
        }
    }
}
