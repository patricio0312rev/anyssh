import AnySSHCore
import Foundation
import Sessions

@MainActor
public final class ReconnectCoordinator {
    public typealias CandidatesProvider = @MainActor () -> [SessionRecord]
    public typealias AttentionProvider = @MainActor () async -> ReconnectAttention
    public typealias ReconnectHandler = @MainActor (SessionID) async -> Void

    private let policy: ReconnectPolicy
    private let pathSignal: any ReconnectPathSignaling
    private var candidates: CandidatesProvider?
    private var attention: AttentionProvider?
    private var onReconnect: ReconnectHandler?
    private var isStarted = false
    private var inFlight = Set<SessionID>()

    public private(set) var pathChangeCount = 0
    public private(set) var lastTriggeredSessionIDs: [SessionID] = []

    public init(
        policy: ReconnectPolicy = ReconnectPolicy(),
        pathSignal: any ReconnectPathSignaling = ReconnectPathSignal()
    ) {
        self.policy = policy
        self.pathSignal = pathSignal
    }

    public var usesInterfaceConstraint: Bool { false }

    public func start(
        candidates: @escaping CandidatesProvider,
        attention: @escaping AttentionProvider,
        onReconnect: @escaping ReconnectHandler
    ) {
        guard !isStarted else { return }
        isStarted = true
        self.candidates = candidates
        self.attention = attention
        self.onReconnect = onReconnect
        pathSignal.start { [weak self] in
            Task { @MainActor in
                self?.handlePathChange()
            }
        }
    }

    public func stop() {
        pathSignal.cancel()
        candidates = nil
        attention = nil
        onReconnect = nil
        isStarted = false
        inFlight.removeAll()
    }

    public func handlePathChange() {
        pathChangeCount += 1
        Task { await requestReconnects(for: .pathChange) }
    }

    public func handleForeground() {
        Task { await requestReconnects(for: .foreground) }
    }

    public func decision(for record: SessionRecord) -> ReconnectDecision {
        policy.decision(
            state: record.state,
            capabilities: record.capabilities,
            recordedAttempts: record.reconnectAttempts
        )
    }

    public func survivalState(for record: SessionRecord) -> ErrorState {
        policy.survivalCopy(for: record.capabilities)
    }

    public func requestReconnects(for trigger: ReconnectTrigger) async {
        guard let candidates, let attention, let onReconnect else { return }
        let dialable = candidates().filter { decision(for: $0).shouldDial }
        let records = await attention().scoped(dialable, for: trigger)
        lastTriggeredSessionIDs = records.map(\.id)
        for record in records {
            guard !inFlight.contains(record.id) else { continue }
            inFlight.insert(record.id)
            await onReconnect(record.id)
            inFlight.remove(record.id)
        }
    }
}
