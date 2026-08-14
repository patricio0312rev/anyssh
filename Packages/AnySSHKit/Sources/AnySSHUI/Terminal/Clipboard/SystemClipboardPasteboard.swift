import AnySSHCore
import Foundation

#if canImport(UIKit)
import UIKit
import UniformTypeIdentifiers
#elseif canImport(AppKit)
import AppKit
#endif

public struct SystemClipboardPasteboard: ClipboardPasteboard, Sendable {
    static let expiry: TimeInterval = 120

    public init() {}

    nonisolated public func write(_ text: String) {
        #if canImport(UIKit)
        let payload = Self.uiPayload(for: text, now: Date())
        UIPasteboard.general.setItems(payload.items, options: payload.options)
        #elseif canImport(AppKit)
        let board = NSPasteboard.general
        board.clearContents()
        board.setString(text, forType: .string)
        #endif
    }

    nonisolated public func read() -> String? {
        #if canImport(UIKit)
        return UIPasteboard.general.string
        #elseif canImport(AppKit)
        return NSPasteboard.general.string(forType: .string)
        #else
        return nil
        #endif
    }
}

#if canImport(UIKit)
extension SystemClipboardPasteboard {
    static func uiPayload(
        for text: String,
        now: Date
    ) -> (items: [[String: Any]], options: [UIPasteboard.OptionsKey: Any]) {
        (
            items: [[UTType.utf8PlainText.identifier: text]],
            options: [
                .localOnly: true,
                .expirationDate: now.addingTimeInterval(expiry),
            ]
        )
    }
}
#endif
