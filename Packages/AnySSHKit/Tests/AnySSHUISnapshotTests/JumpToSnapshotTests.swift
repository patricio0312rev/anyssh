#if canImport(UIKit)
import AnySSHCore
import Testing

@testable import AnySSHUI

@Suite @MainActor struct JumpToSnapshotTests {
    @Test func herdrList() {
        assert(model(kind: .herdr, layout: .list), named: "jumpTo-herdr-list")
    }

    @Test func herdrAccordion() {
        assert(model(kind: .herdr, layout: .accordion), named: "jumpTo-herdr-accordion")
    }

    @Test func herdrGrid() {
        assert(model(kind: .herdr, layout: .grid), named: "jumpTo-herdr-grid")
    }

    @Test func tmuxListExplainsTheMissingDots() {
        assert(model(kind: .tmux, layout: .list), named: "jumpTo-tmux-list")
    }

    @Test func sixtyRowsScrollRatherThanTruncate() {
        assert(
            JumpToModel(sessions: largeTree(), kind: .herdr, layout: .list),
            named: "jumpTo-sixty-rows"
        )
    }

    private func model(kind: MultiplexerKind, layout: JumpLayout) -> JumpToModel {
        JumpToModel(sessions: tree(kind: kind), kind: kind, layout: layout)
    }

    private func tree(kind: MultiplexerKind) -> [JumpSession] {
        let status: (JumpAgentStatus) -> JumpAgentStatus = { kind == .herdr ? $0 : .unknown }
        return [
            JumpSession(
                id: MuxSessionID(rawValue: "default"),
                name: "default",
                groups: [
                    row(
                        "w1:t1",
                        "main",
                        panes: 2,
                        status: status(.waiting("working")),
                        active: true
                    ),
                    row("w1:t2", "notes", panes: 1, status: status(.finished("idle"))),
                    row("w1:t3", "logs", panes: 3, status: status(.waiting("blocked"))),
                ]
            ),
            JumpSession(
                id: MuxSessionID(rawValue: "side"),
                name: "side",
                groups: [
                    row("w2:t1", "agent", panes: 1, status: status(.finished("done"))),
                    row("w2:t2", "shell", panes: 2, status: .unknown),
                ]
            ),
        ]
    }

    private func largeTree() -> [JumpSession] {
        (0..<3).map { sessionIndex in
            let sessionID = MuxSessionID(rawValue: "s\(sessionIndex)")
            let groups = (0..<20).map { groupIndex in
                JumpRow(
                    group: MuxGroup(
                        id: MuxGroupID(rawValue: "s\(sessionIndex):t\(groupIndex)"),
                        sessionID: sessionID,
                        title: "window \(groupIndex)",
                        isActive: groupIndex == 0
                    ),
                    status: groupIndex.isMultiple(of: 3)
                        ? .waiting("working")
                        : .finished("idle"),
                    paneCount: groupIndex % 2 + 1
                )
            }
            return JumpSession(id: sessionID, name: "session \(sessionIndex)", groups: groups)
        }
    }

    private func row(
        _ id: String,
        _ title: String,
        panes: Int,
        status: JumpAgentStatus,
        active: Bool = false
    ) -> JumpRow {
        JumpRow(
            group: MuxGroup(
                id: MuxGroupID(rawValue: id),
                sessionID: MuxSessionID(rawValue: "s"),
                title: title,
                isActive: active
            ),
            status: status,
            paneCount: panes
        )
    }

    private func assert(_ model: JumpToModel, named: String, line: UInt = #line) {
        ComponentSnapshot.assert(
            JumpToSheet(model: model, onDismiss: {}),
            named: named,
            height: 700,
            testName: "JumpTo",
            line: line
        )
    }
}
#endif
