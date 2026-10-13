import AnySSHCore
import Foundation

#if canImport(UIKit)
import UIKit
import UniformTypeIdentifiers
#elseif canImport(AppKit)
import AppKit
#endif

extension SystemClipboardPasteboard: ClipboardContentSource {
    nonisolated public func contentKinds() -> ClipboardContentKinds {
        #if canImport(UIKit)
        let board = UIPasteboard.general
        return ClipboardContentKinds(hasText: board.hasStrings, hasImage: board.hasImages)
        #elseif canImport(AppKit)
        let board = NSPasteboard.general
        return ClipboardContentKinds(
            hasText: board.availableType(from: [.string]) != nil,
            hasImage: board.availableType(from: [.png]) != nil
        )
        #else
        return ClipboardContentKinds(hasText: false, hasImage: false)
        #endif
    }

    nonisolated public func readText() -> String? {
        read()
    }

    nonisolated public func readImage() -> PastedImage? {
        #if canImport(UIKit)
        let board = UIPasteboard.general
        if let png = board.data(forPasteboardType: UTType.png.identifier) {
            return PastedImage(data: png, format: .png)
        }
        if let jpeg = board.data(forPasteboardType: UTType.jpeg.identifier) {
            return PastedImage(data: jpeg, format: .jpeg)
        }
        guard let jpeg = board.image?.jpegData(compressionQuality: 1) else { return nil }
        return PastedImage(data: jpeg, format: .jpeg)
        #elseif canImport(AppKit)
        guard let png = NSPasteboard.general.data(forType: .png) else { return nil }
        return PastedImage(data: png, format: .png)
        #else
        return nil
        #endif
    }
}
