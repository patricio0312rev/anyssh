import AnySSHCore
import Testing

@testable import SSHTransport

@Suite struct TransportEndpointTests {
    @Test func endpointDerivesFromARemote() {
        let remote = Remote(
            id: RemoteID(rawValue: "a"),
            name: "A",
            host: "10.0.0.1",
            port: 2200,
            username: "root"
        )
        #expect(TransportEndpoint(remote: remote).description == "10.0.0.1:2200")
    }

    @Test(
        arguments: [
            ("::1", 22, "[::1]:22"),
            ("fd7a:115c:a1e0::1", 2200, "[fd7a:115c:a1e0::1]:2200"),
            ("100.100.100.100", 22, "100.100.100.100:22"),
            ("mac-mini.ts.net", 22, "mac-mini.ts.net:22"),
        ])
    func bracketsAnIPv6LiteralAndNothingElse(host: String, port: Int, rendered: String) {
        #expect(TransportEndpoint(host: host, port: port).description == rendered)
    }
}
