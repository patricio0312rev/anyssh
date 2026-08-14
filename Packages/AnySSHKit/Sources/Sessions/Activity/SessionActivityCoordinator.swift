import AnySSHCore
import Foundation

public actor SessionActivityCoordinator {
    private let presenter: any ActivityPresenter
    private let clock: any Clock
    private let policy: ActivityPolicy
    private var isForeground = false
    private var trackedID: SessionID?
    private var latestContent: ActivityContent?

    public init(
        presenter: any ActivityPresenter,
        clock: any Clock,
        policy: ActivityPolicy = ActivityPolicy()
    ) {
        self.presenter = presenter
        self.clock = clock
        self.policy = policy
    }

    public func setForeground(_ foreground: Bool) {
        isForeground = foreground
    }

    public func open(
        _ record: SessionRecord,
        remoteName: String,
        notification: String? = nil,
        agentState: String = "idle"
    ) async {
        guard isForeground, trackedID == nil else { return }
        let content = makeContent(
            record, remoteName: remoteName, notification: notification, agentState: agentState
        )
        trackedID = record.id
        latestContent = content
        await presenter.start(content)
    }

    public func update(
        _ record: SessionRecord,
        remoteName: String,
        notification: String? = nil,
        agentState: String = "idle"
    ) async {
        guard trackedID == record.id else { return }
        let content = makeContent(
            record, remoteName: remoteName, notification: notification, agentState: agentState
        )
        latestContent = content
        await presenter.update(content)
    }

    public func close(_ sessionID: SessionID) async {
        guard trackedID == sessionID else { return }
        trackedID = nil
        guard let latestContent else { return }
        self.latestContent = nil
        await presenter.end(latestContent)
    }

    private func makeContent(
        _ record: SessionRecord,
        remoteName: String,
        notification: String?,
        agentState: String
    ) -> ActivityContent {
        policy.content(
            for: record,
            remoteName: remoteName,
            notification: notification,
            agentState: agentState,
            at: clock.now
        )
    }
}
