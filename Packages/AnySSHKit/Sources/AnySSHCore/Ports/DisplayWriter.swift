public protocol DisplayWriter: Sendable {
    func send(_ bytes: ArraySlice<UInt8>) async throws
}
