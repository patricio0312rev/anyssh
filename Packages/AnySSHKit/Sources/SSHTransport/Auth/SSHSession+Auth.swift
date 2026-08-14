import AnySSHCore
import CSSH
import Darwin
import Foundation

extension SSHSession {
    public var isAuthenticated: Bool {
        guard let handle else { return false }
        return libssh2_userauth_authenticated(handle) == 1
    }

    public func offeredMethods(for username: String) async throws -> [String] {
        guard handle != nil else { throw AuthFailure.notConnected }
        let user = strdup(username)
        let userLength = UInt32(username.utf8.count)
        defer { free(user) }
        var list: UnsafeMutablePointer<CChar>?
        _ = try await retrying(deadline: .now + configuration.handshakeTimeout) { session in
            list = libssh2_userauth_list(session, user, userLength)
            guard list == nil else { return 0 }
            let code = libssh2_session_last_errno(session)
            return code == 0 ? 0 : code
        }
        guard let list else { return [] }
        return String(cString: list).split(separator: ",").map(String.init)
    }

    public func authenticate(
        as username: String,
        with credential: AuthCredential,
        answering: AuthPromptAnswering? = nil,
        roundTimeout: Duration = .seconds(120)
    ) async throws {
        guard handle != nil else { throw AuthFailure.notConnected }
        let deadline = ContinuousClock.now + configuration.handshakeTimeout
        switch credential {
        case .privateKey(let key):
            try await attemptPublicKey(key, username: username, deadline: deadline)
        case .password(let password):
            try await attemptPassword(password, username: username, deadline: deadline)
        case .keyboardInteractive:
            guard let answering else { throw AuthFailure.noAnswerer }
            try await attemptKeyboardInteractive(
                username: username,
                answering: answering,
                roundTimeout: roundTimeout
            )
        }
        noteInboundActivity()
    }

    private func attemptPublicKey(
        _ key: AuthPrivateKey,
        username: String,
        deadline: ContinuousClock.Instant
    ) async throws {
        guard handle != nil else { throw AuthFailure.notConnected }
        let user = strdup(username)
        let userLength = username.utf8.count
        let privateKey = copyBytes(key.privateKey)
        let publicKey = key.publicKey.map(copyBytes)
        let passphrase = key.passphrase.flatMap { strdup($0) }
        defer {
            free(user)
            scrubBytes(privateKey)
            publicKey.map(scrubBytes)
            scrub(passphrase)
        }

        let code = try await retrying(deadline: deadline) { session in
            libssh2_userauth_publickey_frommemory(
                session,
                user,
                userLength,
                publicKey?.pointer,
                publicKey?.count ?? 0,
                privateKey.pointer,
                privateKey.count,
                passphrase
            )
        }
        guard code != 0 else { return }
        throw AuthFailure.from(
            code: code,
            message: lastErrorMessage(),
            method: .publicKey,
            encrypted: key.passphrase != nil
        )
    }

    private func attemptPassword(
        _ password: String,
        username: String,
        deadline: ContinuousClock.Instant
    ) async throws {
        guard handle != nil else { throw AuthFailure.notConnected }
        let user = strdup(username)
        let userLength = UInt32(username.utf8.count)
        let secret = strdup(password)
        let secretLength = UInt32(password.utf8.count)
        defer {
            free(user)
            scrub(secret)
        }

        let code = try await retrying(deadline: deadline) { session in
            libssh2_userauth_password_ex(session, user, userLength, secret, secretLength, nil)
        }
        guard code != 0 else { return }
        throw AuthFailure.from(
            code: code,
            message: lastErrorMessage(),
            method: .password,
            encrypted: false
        )
    }
}

private func scrub(_ pointer: UnsafeMutablePointer<CChar>?) {
    guard let pointer else { return }
    memset(pointer, 0, strlen(pointer))
    free(pointer)
}

private typealias KeyBytes = (pointer: UnsafeMutablePointer<CChar>, count: Int)

private func copyBytes(_ data: Data) -> KeyBytes {
    let count = data.count
    let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: Swift.max(count, 1))
    if count > 0 {
        data.withUnsafeBytes { raw in
            if let base = raw.baseAddress { memcpy(pointer, base, count) }
        }
    }
    return (pointer, count)
}

private func scrubBytes(_ bytes: KeyBytes) {
    memset(bytes.pointer, 0, bytes.count)
    bytes.pointer.deallocate()
}
