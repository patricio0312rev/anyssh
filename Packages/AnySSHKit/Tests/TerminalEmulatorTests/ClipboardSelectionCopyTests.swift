import Foundation
import Testing

@testable import TerminalEmulator

@Suite struct ClipboardSelectionCopyTests {
    @Test func selectionCopyWritesPasteboardAndOutboundOSC52() {
        let pasteboard = RecordingPasteboard()
        let transport = RecordingTransportWrites()
        let engine = ClipboardEngine(
            pasteboard: pasteboard,
            onTransportWrite: { transport.append($0) }
        )
        let text = "selected terminal text"
        engine.markRemoteClipboardActive()

        engine.copySelection(text)

        #expect(pasteboard.writes == [text])
        #expect(pasteboard.value == text)
        let joined = transport.joined
        #expect(joined == OSC52Sequence.write(text: text))
        let encoded = Data(text.utf8).base64EncodedString()
        #expect(String(decoding: joined, as: UTF8.self).contains(encoded))
        #expect(joined.last == 0x07)
    }
}
