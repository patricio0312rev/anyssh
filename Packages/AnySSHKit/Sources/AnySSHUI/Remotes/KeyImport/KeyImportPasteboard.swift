import AnySSHCore
import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public protocol KeyImportPasteboard: Sendable {
    func read() -> String?
    func clear()
}

public struct SystemKeyImportPasteboard: KeyImportPasteboard {
    public init() {}

    public func read() -> String? {
        #if canImport(UIKit)
        return UIPasteboard.general.string
        #elseif canImport(AppKit)
        return NSPasteboard.general.string(forType: .string)
        #else
        return nil
        #endif
    }

    public func clear() {
        #if canImport(UIKit)
        UIPasteboard.general.items = []
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        #endif
    }
}
