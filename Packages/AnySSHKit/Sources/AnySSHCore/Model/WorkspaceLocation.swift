public struct WorkspaceLocation: Sendable, Equatable {
    public enum Provenance: String, CaseIterable, Sendable {
        case userOverride
        case multiplexer
        case shellIntegration
        case process
        case `default`
    }

    public let path: String
    public let provenance: Provenance

    public init(path: String, provenance: Provenance) {
        self.path = path
        self.provenance = provenance
    }
}
