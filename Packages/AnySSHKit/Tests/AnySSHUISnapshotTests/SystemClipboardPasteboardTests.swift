#if canImport(UIKit)
import Foundation
import Testing
import UIKit
import UniformTypeIdentifiers

@testable import AnySSHUI

@Suite struct SystemClipboardPasteboardTests {
    @Test func writePayloadIsLocalOnlyWithExpiry() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let payload = SystemClipboardPasteboard.uiPayload(for: "hunter2", now: now)

        #expect(payload.options[.localOnly] as? Bool == true)

        let expiry = payload.options[.expirationDate] as? Date
        #expect(expiry == now.addingTimeInterval(120))
        #expect(expiry != nil)
    }

    @Test func writePayloadCarriesPlainTextItem() {
        let payload = SystemClipboardPasteboard.uiPayload(for: "hunter2", now: Date())
        let item = payload.items.first

        #expect(item?[UTType.utf8PlainText.identifier] as? String == "hunter2")
    }
}
#endif
