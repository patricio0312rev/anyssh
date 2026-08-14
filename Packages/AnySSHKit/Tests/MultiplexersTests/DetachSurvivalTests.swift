import AnySSHCore
import Foundation
import Testing

@testable import Multiplexers

@Suite struct DetachSurvivalTests {
    @Test func threeValueModelMatchesMeasuredConfidence() {
        #expect(MultiplexerCapabilities.tmux.localSessionSurvival == .proven)
        #expect(MultiplexerCapabilities.tmux.remoteBootstrapSurvival == .unsupported)
        #expect(MultiplexerCapabilities.tmux.crossHostSurvival == .proven)

        #expect(MultiplexerCapabilities.herdr.localSessionSurvival == .proven)
        #expect(MultiplexerCapabilities.herdr.remoteBootstrapSurvival == .unverified)
        #expect(MultiplexerCapabilities.herdr.crossHostSurvival == .unverified)

        #expect(MultiplexerCapabilities.none.localSessionSurvival == .unsupported)
    }

    @Test func cardCopyMatchesArchitectureTableForEachCombination() throws {
        let rows = try SurvivalCopyTable.rows()

        let tmux = MuxSurvivalCopy.card(for: .tmux)
        #expect(tmux.localSession == MuxSurvivalCopy.provenLocal)
        #expect(tmux.remoteBootstrap == nil)
        #expect(tmux.crossHost == nil)
        #expect(rows.contains(where: { $0.contains(MuxSurvivalCopy.provenLocal) }))

        let herdr = MuxSurvivalCopy.card(for: .herdr)
        #expect(herdr.localSession == MuxSurvivalCopy.provenLocal)
        #expect(herdr.remoteBootstrap == MuxSurvivalCopy.untestedRemoteBootstrap)
        #expect(herdr.crossHost == MuxSurvivalCopy.untestedCrossHost)
        #expect(herdr.cardLines.count == 3)
        #expect(rows.contains(where: { $0.contains(MuxSurvivalCopy.untestedRemoteBootstrap) }))
        #expect(rows.contains(where: { $0.contains(MuxSurvivalCopy.untestedCrossHost) }))

        let plain = MuxSurvivalCopy.card(for: .none)
        #expect(plain.localSession == MuxSurvivalCopy.unsupportedLocal)
        #expect(plain.remoteBootstrap == nil)
        #expect(plain.crossHost == nil)

        let protocolMismatch = ErrorState.mux(.protocolMismatch)
        #expect(protocolMismatch.stateID == "mux.protocolMismatch")
        #expect(protocolMismatch.copy.title == "Herdr version not supported")
        #expect(rows.contains(where: { $0.contains("`mux.protocolMismatch`") }))
        #expect(rows.contains(where: { $0.contains(protocolMismatch.copy.title) }))
        #expect(rows.contains(where: { $0.contains(protocolMismatch.copy.body) }))
        #expect(rows.contains(where: { $0.contains(protocolMismatch.copy.recoveryLabel) }))

        let absent = ErrorState.mux(.absent)
        #expect(absent.stateID == "mux.absent")
        #expect(rows.contains(where: { $0.contains("`mux.absent`") }))
        #expect(rows.contains(where: { $0.contains(absent.copy.title) }))
    }
}

private enum SurvivalCopyTable {
    static func rows() throws -> [String] {
        let root = repositoryRoot()
        let errorStates = try String(
            contentsOf: root.appending(path: "docs/error-states.md"),
            encoding: .utf8
        )
        let architecture = try String(
            contentsOf: root.appending(path: "docs/ARCHITECTURE.md"),
            encoding: .utf8
        )
        return (errorStates + "\n" + architecture).split(whereSeparator: \.isNewline).map(String.init)
    }

    private static func repositoryRoot() -> URL {
        var url = URL(filePath: #filePath)
        for _ in 0..<5 { url = url.deletingLastPathComponent() }
        return url
    }
}
