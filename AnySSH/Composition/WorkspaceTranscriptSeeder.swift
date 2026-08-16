import AnySSHCore
import AnySSHUI

@MainActor
enum WorkspaceTranscriptSeeder {
    private static let settleInterval = Duration.milliseconds(50)
    private static let settleAttempts = 16

    static func seed(_ scenario: WorkspaceScenario, into engine: any TerminalSurfaceEngine) {
        guard scenario.fitsTranscriptToGrid else {
            feed(scenario, into: engine, size: engine.size)
            return
        }
        Task {
            let size = await settledSize(of: engine)
            feed(scenario, into: engine, size: size)
        }
    }

    private static func feed(
        _ scenario: WorkspaceScenario,
        into engine: any TerminalSurfaceEngine,
        size: TerminalSize
    ) {
        let transcript = scenario.transcript(columns: size.columns, rows: size.rows)
        engine.feed(ArraySlice(transcript))
    }

    private static func settledSize(of engine: any TerminalSurfaceEngine) async -> TerminalSize {
        var previous = engine.size
        var laidOut = false
        for _ in 0..<settleAttempts {
            try? await Task.sleep(for: settleInterval)
            let current = engine.size
            if current != previous {
                laidOut = true
            } else if laidOut {
                return current
            }
            previous = current
        }
        return previous
    }
}
