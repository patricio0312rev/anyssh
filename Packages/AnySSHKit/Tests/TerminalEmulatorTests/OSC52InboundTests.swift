import Foundation
import Testing

@testable import TerminalEmulator

@Suite struct OSC52InboundTests {
    @Test func aDecodedPayloadReachesThePasteboard() {
        let pasteboard = RecordingPasteboard()
        let text = "git status --short"
        let sequence = OSC52Fixtures.sequence(text: text)

        let outcome = OSC52Inbound.handle(sequence: sequence[...], pasteboard: pasteboard)

        #expect(outcome == .wrote(text))
        #expect(pasteboard.writes == [text])
    }

    @Test func utf8MultibyteContentSurvivesTheRoundTrip() {
        let pasteboard = RecordingPasteboard()
        let text = "café — 日本語"
        let sequence = OSC52Fixtures.sequence(text: text)

        let outcome = OSC52Inbound.handle(sequence: sequence[...], pasteboard: pasteboard)

        #expect(outcome == .wrote(text))
        #expect(pasteboard.writes == [text])
    }

    @Test func anOversizedPayloadIsRefusedWithTheNamedCopy() {
        let pasteboard = RecordingPasteboard()
        let oversized = String(repeating: "a", count: OSC52Limits.maxDecodedBytes + 1)
        let sequence = OSC52Fixtures.sequence(text: oversized)

        let outcome = OSC52Inbound.handle(sequence: sequence[...], pasteboard: pasteboard)

        #expect(outcome == .refused(.tooLarge))
        #expect(pasteboard.writes.isEmpty)
        #expect(ClipboardRefusal.tooLarge.copy.title == "Clipboard payload too large")
        #expect(
            ClipboardRefusal.tooLarge.copy.body
                == "The host sent more than 256 KB of clipboard data, so nothing was copied. "
                + "Copy a smaller selection on the host."
        )
        #expect(ClipboardRefusal.tooLarge.accessibilityIdentifier == "error.app.clipboardTooLarge")
    }

    @Test func theEngineRecordsAWriteAndMarksTheRemoteActive() {
        let pasteboard = RecordingPasteboard()
        let engine = ClipboardEngine(pasteboard: pasteboard)
        let text = "yanked from vim"
        let sequence = OSC52Fixtures.sequence(text: text)

        let outcome = engine.feed(sequence[...])

        #expect(outcome == .wrote(text))
        #expect(engine.remoteClipboardActive)
        #expect(pasteboard.writes == [text])
        #expect(engine.lastRefusal == nil)
    }

    @Test func aQueryDoesNotWriteThePasteboard() {
        let pasteboard = RecordingPasteboard("local")
        let engine = ClipboardEngine(pasteboard: pasteboard)
        let sequence = OSC52Sequence.query()

        let outcome = engine.feed(sequence[...])

        #expect(outcome == .query)
        #expect(pasteboard.writes.isEmpty)
        #expect(engine.remoteClipboardActive)
        #expect(!engine.transportLog.snapshot().isEmpty)
    }

    @Test func alreadyDecodedTextIsSizeGatedTheSameWay() {
        let pasteboard = RecordingPasteboard()
        let oversized = String(repeating: "b", count: OSC52Limits.maxDecodedBytes + 1)

        let outcome = OSC52Inbound.handle(decodedText: oversized, pasteboard: pasteboard)

        #expect(outcome == .refused(.tooLarge))
        #expect(pasteboard.writes.isEmpty)
    }
}
