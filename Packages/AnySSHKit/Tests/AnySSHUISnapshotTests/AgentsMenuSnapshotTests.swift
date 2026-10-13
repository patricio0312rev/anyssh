#if canImport(UIKit)
import AnySSHCore
import AnySSHMocks
import Testing

@testable import AnySSHUI

@Suite @MainActor struct AgentsMenuSnapshotTests {
    @Test func herdrAgents() async {
        let model = JumpToModel(
            adapter: FixtureMultiplexerAdapter(fixture: .herdrDefault),
            directory: nil,
            writer: nil
        )
        await model.load()
        assert(model, named: "agents-herdr")
    }

    @Test func noAgents() async {
        let model = JumpToModel(
            adapter: FixtureMultiplexerAdapter(fixture: .tmuxMain),
            directory: nil,
            writer: nil
        )
        await model.load()
        assert(model, named: "agents-empty")
    }

    private func assert(_ model: JumpToModel, named: String, line: UInt = #line) {
        ComponentSnapshot.assert(
            AgentsMenuSheet(model: model, onDismiss: {}),
            named: named,
            height: 700,
            testName: "AgentsMenu",
            line: line
        )
    }
}
#endif
