public protocol CapabilityProbe: Sendable {
    func probe() async throws -> HostCapabilities
}
