public protocol UserFacingError: Error, Sendable {
    var stateID: String { get }
}
