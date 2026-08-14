import AnySSHCore
import TerminalEmulator

@MainActor
public final class TerminalSurfaceStore {
    public typealias EngineFactory = @MainActor (TerminalSize) -> any TerminalSurfaceEngine

    private let makeEngine: EngineFactory
    private let configuration: PumpConfiguration
    public private(set) var jobAlerts: (any NotificationScheduler)?
    private var surfaces = [SessionID: TerminalSurface]()

    public init(
        configuration: PumpConfiguration = .default,
        makeEngine: @escaping EngineFactory,
        jobAlerts: (any NotificationScheduler)? = nil
    ) {
        self.configuration = configuration
        self.makeEngine = makeEngine
        self.jobAlerts = jobAlerts
    }

    public func setJobAlerts(_ jobAlerts: (any NotificationScheduler)?) {
        self.jobAlerts = jobAlerts
        for surface in surfaces.values {
            surface.installJobAlerts(jobAlerts)
        }
    }

    public var count: Int {
        surfaces.count
    }

    public var sessionIDs: Set<SessionID> {
        Set(surfaces.keys)
    }

    public func surface(for id: SessionID) -> TerminalSurface? {
        surfaces[id]
    }

    @discardableResult
    public func open(
        _ id: SessionID,
        on connection: any RemoteConnection,
        size: TerminalSize = .standard,
        deliverMetadata: @escaping TerminalMetadataDelivery = { _ in }
    ) -> TerminalSurface {
        if let existing = surfaces[id] {
            existing.rebind(to: connection)
            return existing
        }
        let surface = TerminalSurface(
            sessionID: id,
            connection: connection,
            engine: makeEngine(size),
            configuration: configuration,
            deliverMetadata: deliverMetadata,
            jobAlerts: jobAlerts
        )
        surfaces[id] = surface
        surface.startDraining()
        return surface
    }

    public func close(_ id: SessionID, reason: DisconnectReason = .closedByUser) async {
        guard let surface = surfaces.removeValue(forKey: id) else { return }
        surface.stopDraining()
        surface.detachFromHost()
        await surface.connection.close(reason: reason)
    }

    public func closeAll(reason: DisconnectReason = .closedByUser) async {
        for id in Array(surfaces.keys) {
            await close(id, reason: reason)
        }
    }
}
