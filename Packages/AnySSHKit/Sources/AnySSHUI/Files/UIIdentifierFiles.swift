extension UIIdentifier.Workspace {
    public static let browser = "workspace.files.browser"
    public static let breadcrumb = "workspace.files.breadcrumb"
    public static let preview = "workspace.files.preview"
    public static let previewToggle = "workspace.files.preview.toggle"

    public static func entry(_ name: String) -> String {
        "workspace.files.entry.\(name)"
    }
}

extension UIIdentifier {
    public enum File {
        public static let sourceViewer = "file.source.viewer"
        public static let jsonViewer = "file.json.viewer"
        public static let svgViewer = "file.svg.viewer"
        public static let videoViewer = "file.video.viewer"
        public static let videoDownload = "file.video.download"
        public static let markdownViewer = "file.markdown.viewer"
        public static let codeContent = "file.code.content"
        public static let jsonFormat = "file.json.format"
        public static let jsonMode = "file.json.mode"
        public static let jsonTree = "file.json.tree"
        public static let imageComparison = "file.image.comparison"
        public static let imageMode = "file.image.mode"
        public static let imageFraction = "file.image.fraction"
        public static let imageDimensions = "file.image.dimensions"
        public static let imageViewer = "file.image.viewer"

        public static func jsonRow(_ id: String) -> String {
            "file.json.row.\(id)"
        }
    }
}
