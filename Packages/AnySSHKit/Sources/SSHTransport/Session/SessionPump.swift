import AnySSHCore
import CSSH

public struct SessionByteReader: Sendable {
    public typealias Read = @Sendable (UnsafeMutableRawBufferPointer) -> Int

    public let read: Read

    public init(read: @escaping Read) {
        self.read = read
    }
}

extension SSHSession {
    public func pump(from reader: SessionByteReader, into sink: any ByteSink) async throws {
        let buffer = UnsafeMutableRawBufferPointer.allocate(
            byteCount: configuration.readBufferSize,
            alignment: 16
        )
        defer { buffer.deallocate() }

        while true {
            let count = reader.read(buffer)
            if count > 0 {
                noteInboundActivity()
                let chunk = [UInt8](UnsafeRawBufferPointer(rebasing: buffer[0..<count]))
                await sink.ingest(chunk[...])
                continue
            }
            if count == 0 { return }
            guard count == Int(LIBSSH2_ERROR_EAGAIN) else {
                throw TransportFailure.connectionLost(code: Int32(clamping: count))
            }
            try await waitForSocket(deadline: nil)
        }
    }
}
