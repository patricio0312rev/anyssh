import AnySSHCore
import Foundation
import Testing

@testable import AnySSHUI

@Suite struct TerminalOscRoutingTests {
    @Test func titleAndWorkingDirectoryReachTheDelegate() async {
        let engine = SwiftTermEngine(size: .standard, renderer: .coreText)
        let delegate = TerminalDelegateSpy()
        engine.setDelegate(delegate)

        engine.feed(TerminalFixture.frame[...])
        await Task.yield()

        #expect(delegate.title == TerminalFixture.title)
        #expect(delegate.workingDirectory == TerminalFixture.workingDirectory)
    }

    @Test func anEncodedWorkingDirectoryArrivesAsAPath() {
        let engine = SwiftTermEngine(size: .standard, renderer: .coreText)
        let delegate = TerminalDelegateSpy()
        engine.setDelegate(delegate)

        engine.feed(Array("\u{1b}]7;file://build-box/Users/pat/My%20Repos/anyssh\u{7}".utf8)[...])

        #expect(delegate.workingDirectory == "/Users/pat/My Repos/anyssh")
    }

    @Test func clipboardCrossesInBothDirections() {
        let engine = SwiftTermEngine(size: .standard, renderer: .coreText)
        let delegate = TerminalDelegateSpy()
        delegate.clipboard = TerminalFixture.clipboardPayload
        engine.setDelegate(delegate)
        let encoded = Data(TerminalFixture.clipboardPayload.utf8).base64EncodedString()

        engine.feed(Array("\u{1b}]52;c;\(encoded)\u{7}".utf8)[...])
        engine.feed(Array("\u{1b}]52;c;?\u{7}".utf8)[...])

        #expect(delegate.clipboardWrites == [TerminalFixture.clipboardPayload])
        #expect(delegate.clipboardReads == 1)
        #expect(String(decoding: delegate.input, as: UTF8.self).contains(encoded))
    }

    @Test func theBellRings() {
        let engine = SwiftTermEngine(size: .standard, renderer: .coreText)
        let delegate = TerminalDelegateSpy()
        engine.setDelegate(delegate)

        engine.feed(Array("done\u{7}".utf8)[...])

        #expect(delegate.rings == 1)
    }

    @Test func aLayoutDrivenResizeIsReportedOnce() {
        let engine = SwiftTermEngine(size: .standard, renderer: .coreText)
        let delegate = TerminalDelegateSpy()
        engine.setDelegate(delegate)

        engine.resize(to: TerminalSize(columns: 120, rows: 40))

        #expect(delegate.sizes.map(\.columns) == [120])
        #expect(delegate.sizes.map(\.rows) == [40])
    }
}

final class TerminalDelegateSpy: TerminalEngineDelegate {
    var title: String?
    var workingDirectory: String?
    var clipboard: String?
    var clipboardWrites: [String] = []
    var clipboardReads = 0
    var rings = 0
    var input: [UInt8] = []
    var sizes: [TerminalSize] = []

    func engine(_ engine: any TerminalEngine, didChangeTitle title: String) {
        self.title = title
    }

    func engine(_ engine: any TerminalEngine, didReportWorkingDirectory path: String) {
        workingDirectory = path
    }

    func engine(_ engine: any TerminalEngine, didRequestClipboardWrite text: String) {
        clipboardWrites.append(text)
    }

    func engineDidRequestClipboardRead(_ engine: any TerminalEngine) -> String? {
        clipboardReads += 1
        return clipboard
    }

    func engineDidRing(_ engine: any TerminalEngine) {
        rings += 1
    }

    func engine(_ engine: any TerminalEngine, didProduceInput bytes: ArraySlice<UInt8>) {
        input.append(contentsOf: bytes)
    }

    func engine(_ engine: any TerminalEngine, didResizeTo size: TerminalSize) {
        sizes.append(size)
    }
}
