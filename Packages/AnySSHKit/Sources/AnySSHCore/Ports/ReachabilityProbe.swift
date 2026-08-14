public protocol ReachabilityProbe: Sendable {
    func probe(_ remote: Remote) async -> Reachability
}
