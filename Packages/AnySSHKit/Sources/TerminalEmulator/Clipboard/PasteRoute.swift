import AnySSHCore
import Foundation

public enum PasteRoute: Sendable, Hashable {
    case text(String)
    case image(Data)
    case unreadableImage
    case empty
    case denied

    @MainActor
    public static func resolve(from source: any ClipboardContentSource) -> PasteRoute {
        let kinds = source.contentKinds()
        if kinds.hasImage {
            guard let data = source.readImage() else { return .denied }
            return data.isEmpty ? .unreadableImage : .image(data)
        }
        guard kinds.hasText else { return .empty }
        guard let text = source.readText() else { return .denied }
        return text.isEmpty ? .empty : .text(text)
    }
}
