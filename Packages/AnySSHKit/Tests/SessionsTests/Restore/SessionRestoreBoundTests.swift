import AnySSHCore
import Testing

@testable import Sessions

@MainActor
@Suite struct SessionRestoreBoundTests {
    @Test func thePersistedTailIsExactlyTheFloor() {
        let dump = (0..<(SessionRestorePolicy.persistedTailLines * 5)).map { "line \($0)" }
            .joined(separator: "\n")

        let tail = SessionRestoreTranscript.tail(
            of: dump,
            maxLines: SessionRestorePolicy.persistedTailLines
        )

        #expect(tail.count == SessionRestorePolicy.persistedTailLines)
        #expect(tail.last == "line \(SessionRestorePolicy.persistedTailLines * 5 - 1)")
    }

    @Test func restoringFeedsExactlyTheBoundAndNeverTrims() {
        let lines = (0..<(SessionRestorePolicy.persistedTailLines + 10))
            .map { "line \($0)" }
        let engine = RecordingEngine()

        SessionRestoreTranscript.restore(lines, into: engine)

        #expect(engine.lineCount == SessionRestorePolicy.persistedTailLines)
        #expect(engine.scrollbackLimitCalls.isEmpty)
    }

    @Test func restoringEmptyTranscriptFeedsNothing() {
        let engine = RecordingEngine()

        SessionRestoreTranscript.restore([], into: engine)

        #expect(engine.lineCount == 0)
        #expect(engine.scrollbackLimitCalls.isEmpty)
    }
}

@MainActor
private final class RecordingEngine: TerminalEngine {
    var size: TerminalSize { .standard }
    private(set) var lineCount = 0
    private(set) var scrollbackLimitCalls: [Int] = []

    func setDelegate(_ delegate: any TerminalEngineDelegate) {}

    func feed(_ bytes: ArraySlice<UInt8>) {
        lineCount += bytes.filter { $0 == UInt8(ascii: "\n") }.count
        if !bytes.isEmpty, bytes.last != UInt8(ascii: "\n") {
            lineCount += 1
        }
    }

    func resize(to size: TerminalSize) {}

    func setScrollbackLimit(_ lines: Int) {
        scrollbackLimitCalls.append(lines)
    }
}
