import AnySSHCore
import CSSH

extension SSHSession {
    public var negotiatedHostKey: HostKey? {
        guard let handle else { return nil }
        var byteCount = 0
        var type: Int32 = 0
        guard let blob = libssh2_session_hostkey(handle, &byteCount, &type), byteCount > 0 else {
            return nil
        }
        return HostKey(blob: [UInt8](UnsafeRawBufferPointer(start: blob, count: byteCount)))
    }

    public var negotiatedHostKeyDigest: [UInt8]? {
        guard let handle, let digest = libssh2_hostkey_hash(handle, LIBSSH2_HOSTKEY_HASH_SHA256) else {
            return nil
        }
        return (0..<32).map { UInt8(bitPattern: digest[$0]) }
    }

    @discardableResult
    public func verifyHostKey(_ trust: HostKeyTrust) async throws -> HostKeyTrustOutcome {
        guard let offered = negotiatedHostKey else { throw TransportFailure.notConnected }
        let outcome = try await trust.evaluate(offered, host: target.host, port: target.port)
        if let failure = outcome.failure { throw failure }
        return outcome
    }

    func gateOnHostKey() async throws -> HostKeyTrustOutcome {
        do {
            let outcome = try await withTaskExecutorPreference(DelegateExecutor.shared) {
                try await verifyHostKey(trust)
            }
            trustOutcome = outcome
            return outcome
        } catch {
            let stateID = (error as? any UserFacingError)?.stateID ?? "transport.connectionLost"
            close(reason: .failed(stateID: stateID))
            throw error
        }
    }
}
