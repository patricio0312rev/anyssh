public protocol ByteSink: Sendable {
    func ingest(_ bytes: ArraySlice<UInt8>) async
}
