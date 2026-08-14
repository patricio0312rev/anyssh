import Foundation
import Testing

@testable import TerminalEmulator

@Suite struct OSC52OutboundTests {
    @Test func aSmallPayloadIsOneChunkEndingInBEL() {
        let chunks = OSC52Outbound.chunks(for: "hi")
        let joined = chunks.flatMap { $0 }

        #expect(chunks.count == 1)
        #expect(joined == OSC52Sequence.write(text: "hi"))
        #expect(joined.last == 0x07)
        #expect(String(bytes: joined, encoding: .utf8)?.hasPrefix("\u{1b}]52;c;") == true)
    }

    @Test func aThreeHundredKilobyteClipboardSplitsOnChunkBoundaries() {
        let text = String(repeating: "x", count: 300 * 1024)
        let chunkBytes = OSC52Limits.transportChunkBytes
        let chunks = OSC52Outbound.chunks(for: text, chunkBytes: chunkBytes)
        let expected = OSC52Sequence.write(text: text)
        let joined = chunks.flatMap { $0 }

        #expect(joined == expected)
        #expect(joined.last == 0x07)
        #expect(chunks.count == (expected.count + chunkBytes - 1) / chunkBytes)
        for (index, chunk) in chunks.enumerated() {
            if index < chunks.count - 1 {
                #expect(chunk.count == chunkBytes)
            } else {
                #expect(chunk.count == expected.count % chunkBytes || chunk.count == chunkBytes)
                #expect(chunk.count > 0)
                #expect(chunk.count <= chunkBytes)
            }
        }
        #expect(chunks.dropLast().allSatisfy { $0.count == chunkBytes })
        #expect(chunks.last?.last == 0x07)
    }

    @Test func theEngineWritesEveryChunkToTheTransport() {
        let pasteboard = RecordingPasteboard()
        let written = RecordingTransportWrites()
        let engine = ClipboardEngine(
            pasteboard: pasteboard,
            chunkBytes: 64,
            onTransportWrite: { written.append($0) }
        )
        engine.markRemoteClipboardActive()
        let text = String(repeating: "ab", count: 80)

        engine.copySelection(text)

        #expect(pasteboard.writes == [text])
        #expect(written.chunks == engine.transportLog.snapshot())
        #expect(written.joined == OSC52Sequence.write(text: text))
        #expect(written.count > 1)
        #expect(written.chunks.dropLast().allSatisfy { $0.count == 64 })
    }

    @Test func selectionCopySkipsOutboundUntilTheRemoteHasAsked() {
        let pasteboard = RecordingPasteboard()
        let written = RecordingTransportWrites()
        let engine = ClipboardEngine(
            pasteboard: pasteboard,
            onTransportWrite: { written.append($0) }
        )

        engine.copySelection("local only")

        #expect(pasteboard.writes == ["local only"])
        #expect(written.isEmpty)
    }
}
