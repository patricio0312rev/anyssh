import AnySSHCore
import Foundation
import Testing

@testable import AnySSHUI

@Suite struct TerminalOSCJobAlertTests {
    @Test func osc52StillReachesTheClipboardAfterRegisteringJobAlertHandlers() {
        let engine = SwiftTermEngine(size: .standard, renderer: .coreText)
        let delegate = TerminalDelegateSpy()
        engine.setDelegate(delegate)
        registerJobAlertHandlers(on: engine)

        let text = "copied text"
        let encoded = Data(text.utf8).base64EncodedString()
        engine.feed(Array("\u{1b}]52;c;\(encoded)\u{7}".utf8)[...])

        #expect(delegate.clipboardWrites == [text])
    }

    @Test func jobAlertPayloadsReachTheRegisteredHandlers() {
        let engine = SwiftTermEngine(size: .standard, renderer: .coreText)
        let delegate = TerminalDelegateSpy()
        engine.setDelegate(delegate)
        var received = [Int: String]()
        registerJobAlertHandlers(on: engine) { code, payload in
            received[code] = String(decoding: payload, as: UTF8.self)
        }

        engine.feed(Array("\u{1b}]9;Backup finished\u{7}".utf8)[...])
        engine.feed(Array("\u{1b}]777;notify;Sync done;Backups synced\u{7}".utf8)[...])
        engine.feed(Array("\u{1b}]133;D;1\u{7}".utf8)[...])

        #expect(received[9] == "Backup finished")
        #expect(received[777] == "notify;Sync done;Backups synced")
        #expect(received[133] == "D;1")
    }

    private func registerJobAlertHandlers(
        on engine: SwiftTermEngine,
        handler: ((Int, ArraySlice<UInt8>) -> Void)? = nil
    ) {
        for code in [9, 777, 133] {
            engine.registerOSCHandler(code: code) { payload in
                handler?(code, payload)
            }
        }
    }
}
