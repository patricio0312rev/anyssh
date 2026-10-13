import AnySSHCore
import Foundation

#if canImport(UIKit)
import UIKit
import UniformTypeIdentifiers
#elseif canImport(AppKit)
import AppKit
#endif

extension SystemClipboardPasteboard: ClipboardContentSource {
    @MainActor
    public func contentKinds() -> ClipboardContentKinds {
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

    @MainActor
    public func readText() -> String? {
        read()
    }

    @MainActor
    public func readImage() -> Data? {
        #if canImport(UIKit)
        let board = UIPasteboard.general
        let preferred = [UTType.png.identifier, UTType.jpeg.identifier]
        let declared = board.types.filter { UTType($0)?.conforms(to: .image) == true }
        for type in preferred + declared {
            if let data = board.data(forPasteboardType: type) {
                return data
            }
        }
        return nil
        #elseif canImport(AppKit)
        return NSPasteboard.general.data(forType: .png)
        #else
        return nil
        #endif
    }
}
