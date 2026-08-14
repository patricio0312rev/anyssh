import AnySSHCore
import Foundation

#if canImport(UIKit)
import UIKit
#endif

public struct SystemClipboardPasteboard: ClipboardPasteboard {
    public init() {}

    public func write(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }

    public func read() -> String? {
        #if canImport(UIKit)
        return UIPasteboard.general.string
        #else
        return nil
        #endif
    }
}
