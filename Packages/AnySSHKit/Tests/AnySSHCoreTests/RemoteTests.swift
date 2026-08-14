import Testing

@testable import AnySSHCore

@Suite struct RemoteTests {
    @Test func endpointOmitsTheDefaultPort() {
        let remote = Remote(
            id: RemoteID(rawValue: "a"),
            name: "A",
            host: "example.com",
            username: "root"
        )
        #expect(remote.endpoint == "root@example.com")
    }

    @Test func endpointIncludesANonDefaultPort() {
        let remote = Remote(
            id: RemoteID(rawValue: "b"),
            name: "B",
            host: "example.com",
            port: 2222,
            username: "ci"
        )
        #expect(remote.endpoint == "ci@example.com:2222")
    }
}
