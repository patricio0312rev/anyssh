public protocol ReconnectPathSignaling: AnyObject, Sendable {
    func start(onChange: @escaping @Sendable () -> Void)
    func cancel()
}
