import SwiftUI

public struct FileIconView: View {
    private let name: FileIconName
    private let size: CGFloat

    @Environment(\.fileIconImageProvider) private var provider

    public init(name: FileIconName, size: CGFloat = Theme.Space.iconGlyph) {
        self.name = name
        self.size = size
    }

    public init(fileName: String, size: CGFloat = Theme.Space.iconGlyph) {
        self.name = FileIconResolver.icon(forFile: fileName)
        self.size = size
    }

    public init(
        folderName: String,
        expanded: Bool = false,
        isRoot: Bool = false,
        size: CGFloat = Theme.Space.iconGlyph
    ) {
        self.name = FileIconResolver.icon(forFolder: folderName, expanded: expanded, isRoot: isRoot)
        self.size = size
    }

    public var body: some View {
        Group {
            if let image = provider.image(for: name) {
                image
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: fallbackSystemName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Theme.text.secondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var fallbackSystemName: String {
        let raw = name.rawValue
        if raw == FileIconName.folder.rawValue || raw.hasPrefix("folder-") {
            return raw.hasSuffix("-open") ? "folder" : "folder.fill"
        }
        return "doc"
    }
}
