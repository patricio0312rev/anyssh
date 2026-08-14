import AnySSHCore
import CSSH

extension SSHSession {
    public func streamShell(_ channel: SSHChannel, into sink: any ByteSink) async throws {
        let buffer = UnsafeMutableRawBufferPointer.allocate(
            byteCount: configuration.readBufferSize,
            alignment: 16
        )
        defer { buffer.deallocate() }

        while true {
            try Task.checkCancellation()
            try live(channel)
            let count = read(channel, into: buffer)
            if count > 0 {
                noteInboundActivity()
                let chunk = [UInt8](UnsafeRawBufferPointer(rebasing: buffer[0..<count]))
                await sink.ingest(chunk[...])
                continue
            }
            if hasEnded(channel, count) { return }
            guard count == 0 || count == Int(LIBSSH2_ERROR_EAGAIN) else {
                throw TransportFailure.connectionLost(code: Int32(clamping: count))
            }
            try await waitForSocket(deadline: nil)
        }
    }

    private func hasEnded(_ channel: SSHChannel, _ count: Int) -> Bool {
        if count == Int(LIBSSH2_ERROR_CHANNEL_CLOSED) { return true }
        return count == 0 && libssh2_channel_eof(channel.pointer) != 0
    }

    public func writeShell(
        _ channel: SSHChannel,
        _ bytes: ArraySlice<UInt8>,
        deadline: ContinuousClock.Instant? = nil
    ) async throws {
        try live(channel)
        guard !bytes.isEmpty else { return }
        let payload = [UInt8](bytes)
        var written = 0

        while written < payload.count {
            try Task.checkCancellation()
            let count = try await retrying(deadline: deadline) { _ in
                Int32(clamping: self.write(channel, payload, from: written))
            }
            guard count > 0 else {
                throw TransportFailure.connectionLost(code: count)
            }
            written += Int(count)
        }
    }

    func mergeExtendedData(_ channel: SSHChannel, deadline: ContinuousClock.Instant) async throws {
        try live(channel)
        _ = try await retrying(deadline: deadline) { _ in
            libssh2_channel_handle_extended_data2(
                channel.pointer,
                Int32(LIBSSH2_CHANNEL_EXTENDED_DATA_MERGE)
            )
        }
    }

    private func read(_ channel: SSHChannel, into buffer: UnsafeMutableRawBufferPointer) -> Int {
        guard let base = buffer.baseAddress else { return 0 }
        return libssh2_channel_read_ex(
            channel.pointer,
            0,
            base.assumingMemoryBound(to: CChar.self),
            buffer.count
        )
    }

    private func write(_ channel: SSHChannel, _ payload: [UInt8], from offset: Int) -> Int {
        payload.withUnsafeBytes { raw in
            guard let base = raw.baseAddress else { return 0 }
            return libssh2_channel_write_ex(
                channel.pointer,
                0,
                base.advanced(by: offset).assumingMemoryBound(to: CChar.self),
                payload.count - offset
            )
        }
    }
}
