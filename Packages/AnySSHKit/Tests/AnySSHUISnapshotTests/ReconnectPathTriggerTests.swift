import AnySSHCore
import Foundation
import Sessions
import Testing

@testable import AnySSHUI

final class ScriptedPathSignal: ReconnectPathSignaling, @unchecked Sendable {
    private let lock = NSLock()
    private var handler: (@Sendable () -> Void)?
    private(set) var startCount = 0
    private(set) var cancelCount = 0

    func start(onChange: @escaping @Sendable () -> Void) {
        lock.lock()
        startCount += 1
        handler = onChange
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        cancelCount += 1
        handler = nil
        lock.unlock()
    }

    func emit() {
        lock.lock()
        let handler = handler
        lock.unlock()
        handler?()
    }
}

@Suite struct ReconnectPathTriggerTests {
    @Test func pathChangesTriggerReconnectWithoutAnInterfaceConstraint() async {
        let signal = ScriptedPathSignal()
        let coordinator = ReconnectCoordinator(pathSignal: signal)
        let record = SessionRecord(
            id: SessionID(rawValue: "s1"),
            remoteID: RemoteID(rawValue: "r1"),
            connectionID: ConnectionID(rawValue: "c1"),
            title: "host",
            state: .disconnected(.backgrounded),
            capabilities: .ssh,
            reconnectAttempts: 0,
            createdAt: Date(timeIntervalSince1970: 0),
            lastActiveAt: Date(timeIntervalSince1970: 0)
        )
        let triggered = LockedIDs()
        coordinator.start(
            candidates: { [record] },
            onReconnect: { id in
                triggered.append(id)
            }
        )
        #expect(signal.startCount == 1)
        signal.emit()
        let deadline = ContinuousClock.now + .seconds(5)
        while triggered.snapshot().isEmpty, ContinuousClock.now < deadline {
            await Task.yield()
        }
        #expect(triggered.snapshot() == [SessionID(rawValue: "s1")])
        #expect(coordinator.usesInterfaceConstraint == false)
        #expect(coordinator.pathChangeCount == 1)
        #expect(coordinator.lastTriggeredSessionIDs == [SessionID(rawValue: "s1")])
    }
}

private final class LockedIDs: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [SessionID] = []

    func append(_ id: SessionID) {
        lock.lock()
        storage.append(id)
        lock.unlock()
    }

    func snapshot() -> [SessionID] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}
