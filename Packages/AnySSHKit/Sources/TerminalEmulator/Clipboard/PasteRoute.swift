import AnySSHCore

public enum PasteRoute: Sendable, Hashable {
    case text(String)
    case image(PastedImage)
    case empty
    case denied

    public static func resolve(from source: any ClipboardContentSource) -> PasteRoute {
        let kinds = source.contentKinds()
        if kinds.hasImage, let image = source.readImage(), !image.data.isEmpty {
            return .image(image)
        }
        if kinds.hasText, let text = source.readText(), !text.isEmpty {
            return .text(text)
        }
        return kinds.hasImage || kinds.hasText ? .denied : .empty
    }
}
