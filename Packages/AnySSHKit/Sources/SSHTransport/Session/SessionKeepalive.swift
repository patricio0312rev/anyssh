import CSSH

extension SSHSession {
    @discardableResult
    public func sendKeepalive() async throws -> Duration {
        guard handle != nil else { throw record(TransportFailure.notConnected) }
        guard timeSinceLastInbound <= configuration.deadPeerTimeout else {
            throw record(TransportFailure.keepaliveTimeout)
        }

        var secondsToNext: Int32 = 0
        do {
            let code = try await retrying(deadline: lastInbound + configuration.deadPeerTimeout) {
                libssh2_keepalive_send($0, &secondsToNext)
            }
            guard code == 0 else { throw TransportFailure.connectionLost(code: code) }
        } catch {
            throw record(error)
        }
        return .seconds(max(1, Int(secondsToNext)))
    }
}
