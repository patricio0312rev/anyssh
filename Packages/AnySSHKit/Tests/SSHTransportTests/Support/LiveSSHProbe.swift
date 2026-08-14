import CSSH
import Foundation
import SSHTransport

struct LiveSSHProbe {
    struct Outcome: Sendable {
        var output: String
        var exitStatus: Int32
        var hostKeyType: Int32
        var hostKeyByteCount: Int
        var hostKeyFingerprint: String
    }

    enum Failure: Error {
        case unreachable
        case sessionInit
        case handshake(Int32)
        case hostKeyUnavailable
        case authentication(Int32)
        case channelOpen
        case exec(Int32)
    }

    var host: LiveHost

    func run(command: String) throws -> Outcome {
        try LibSSH2.withLibrary { try connectAndRun(command) }
    }

    private func connectAndRun(_ command: String) throws -> Outcome {
        guard let descriptor = PosixSocket.connect(host: host.host, port: host.port, timeout: 5)
        else { throw Failure.unreachable }
        defer { PosixSocket.close(descriptor) }

        guard let session = libssh2_session_init_ex(nil, nil, nil, nil) else {
            throw Failure.sessionInit
        }
        defer {
            libssh2_session_disconnect_ex(
                session, SSH_DISCONNECT_BY_APPLICATION, "anyssh smoke test", "")
            libssh2_session_free(session)
        }
        libssh2_session_set_blocking(session, 1)

        let handshake = libssh2_session_handshake(session, descriptor)
        guard handshake == 0 else { throw Failure.handshake(handshake) }

        let hostKey = try readHostKey(session)
        try authenticate(session)
        let (output, exitStatus) = try execute(command, on: session)

        return Outcome(
            output: output,
            exitStatus: exitStatus,
            hostKeyType: hostKey.type,
            hostKeyByteCount: hostKey.byteCount,
            hostKeyFingerprint: hostKey.fingerprint
        )
    }

    private func readHostKey(
        _ session: OpaquePointer
    ) throws -> (type: Int32, byteCount: Int, fingerprint: String) {
        var byteCount = 0
        var type: Int32 = 0
        guard libssh2_session_hostkey(session, &byteCount, &type) != nil,
            let digest = libssh2_hostkey_hash(session, LIBSSH2_HOSTKEY_HASH_SHA256)
        else { throw Failure.hostKeyUnavailable }

        let fingerprint = (0..<32)
            .map { String(format: "%02x", UInt8(bitPattern: digest[$0])) }
            .joined()
        return (type, byteCount, fingerprint)
    }

    private func authenticate(_ session: OpaquePointer) throws {
        let code = host.username.withCString { user in
            libssh2_userauth_publickey_fromfile_ex(
                session,
                user,
                UInt32(host.username.utf8.count),
                host.publicKeyPath,
                host.privateKeyPath,
                nil
            )
        }
        guard code == 0 else { throw Failure.authentication(code) }
    }

    private func execute(
        _ command: String,
        on session: OpaquePointer
    ) throws -> (output: String, exitStatus: Int32) {
        guard
            let channel = libssh2_channel_open_ex(
                session, "session", 7, 2 * 1024 * 1024, 32768, nil, 0)
        else { throw Failure.channelOpen }
        defer { libssh2_channel_free(channel) }

        let started = command.withCString { text in
            libssh2_channel_process_startup(
                channel, "exec", 4, text, UInt32(command.utf8.count))
        }
        guard started == 0 else { throw Failure.exec(started) }

        var bytes = [UInt8]()
        var buffer = [CChar](repeating: 0, count: 4096)
        while true {
            let read = buffer.withUnsafeMutableBufferPointer { slot -> Int in
                guard let base = slot.baseAddress else { return -1 }
                return libssh2_channel_read_ex(channel, 0, base, slot.count)
            }
            guard read > 0 else { break }
            bytes.append(contentsOf: buffer[0..<read].map { UInt8(bitPattern: $0) })
        }

        _ = libssh2_channel_close(channel)
        return (String(decoding: bytes, as: UTF8.self), libssh2_channel_get_exit_status(channel))
    }
}
