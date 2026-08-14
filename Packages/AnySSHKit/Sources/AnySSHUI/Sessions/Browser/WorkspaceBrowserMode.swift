public enum WorkspaceBrowserMode: String, CaseIterable, Hashable, Identifiable, Sendable {
    case changes
    case files

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .changes: "Changes"
        case .files: "Files"
        }
    }

    public var toggleIcon: String {
        switch self {
        case .changes: "folder"
        case .files: "arrow.triangle.branch"
        }
    }

    public var toggleLabel: String {
        switch self {
        case .changes: "Show files"
        case .files: "Show changes"
        }
    }

    public var next: WorkspaceBrowserMode {
        self == .changes ? .files : .changes
    }
}
