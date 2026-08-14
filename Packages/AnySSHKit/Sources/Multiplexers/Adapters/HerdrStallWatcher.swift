import AnySSHCore

public actor HerdrStallWatcher {
    private let sessionID: SessionID
    private let scheduler: any NotificationScheduler
    private let onState: (@Sendable (String) -> Void)?
    private var states = [MuxPaneID: String]()

    public init(
        sessionID: SessionID,
        scheduler: any NotificationScheduler,
        onState: (@Sendable (String) -> Void)? = nil
    ) {
        self.sessionID = sessionID
        self.scheduler = scheduler
        self.onState = onState
    }

    public func ingest(_ snapshot: MuxSnapshot) async {
        let state = sessionState(snapshot.panes)
        onState?(state)
        for pane in snapshot.panes {
            let state = pane.agentStatus?.lowercased() ?? "unknown"
            if let previous = states[pane.id], previous != state,
                state == "blocked" || state == "done"
            {
                await scheduler.schedule(
                    JobAlertRequest(
                        alert: JobFinishAlert(
                            title: pane.title,
                            body: state == "blocked" ? "The agent is waiting for you." : "The agent is done."
                        ),
                        sessionID: sessionID,
                        paneID: pane.id
                    )
                )
            }
            states[pane.id] = state
        }
    }

    private func sessionState(_ panes: [MuxPane]) -> String {
        let states = Set(panes.compactMap { $0.agentStatus?.lowercased() })
        if states.contains("blocked") { return "blocked" }
        if states.contains("working") { return "working" }
        if states.contains("done") { return "done" }
        return "idle"
    }
}
