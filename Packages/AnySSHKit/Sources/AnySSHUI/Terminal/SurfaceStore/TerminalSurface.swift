import AnySSHCore
import TerminalEmulator

@MainActor
public final class TerminalSurface {
    public let sessionID: SessionID
    public private(set) var writeFailure: ErrorState?
    public private(set) var connection: any RemoteConnection
    public private(set) var connectionID: ConnectionID
    public let engine: any TerminalSurfaceEngine
    public let pump: OutputPump
    public let metadata: TerminalMetadataCoalescer

    private let counter: TerminalByteCounter
    private let bridge: TerminalSurfaceBridge
    private var drain: Task<Void, Never>?
    private var retiring: Task<Void, Never>?

    public var view: TerminalPlatformView {
        engine.surface
    }

    public var bytesReceived: Int {
        counter.bytes
    }

    public var isDraining: Bool {
        drain != nil
    }

    public init(
        sessionID: SessionID,
        connection: any RemoteConnection,
        engine: any TerminalSurfaceEngine,
        configuration: PumpConfiguration = .default,
        deliverMetadata: @escaping TerminalMetadataDelivery = { _ in },
        jobAlerts: (any NotificationScheduler)? = nil
    ) {
        let counter = TerminalByteCounter()
        let coalescer = TerminalMetadataCoalescer()
        let bridge = TerminalSurfaceBridge(connection: connection, metadata: coalescer)
        let target = EngineDrainTarget(
            engine: engine,
            metadata: coalescer,
            deliverMetadata: deliverMetadata
        )
        self.sessionID = sessionID
        connectionID = connection.connectionID
        self.connection = connection
        self.engine = engine
        metadata = coalescer
        self.bridge = bridge
        self.counter = counter
        pump = OutputPump(configuration: configuration) { bytes in
            target.receive(bytes)
            counter.add(bytes.count)
        }
        bridge.onWriteFailure = { [weak self] error in
            self?.writeFailure = (error as? ErrorState) ?? .transport(.keepaliveTimeout)
        }
        engine.setDelegate(bridge)
        installJobAlerts(jobAlerts)
    }

    deinit {
        drain?.cancel()
    }

    public func rebind(to connection: any RemoteConnection) {
        guard self.connection !== connection else { return }
        self.connection = connection
        connectionID = connection.connectionID
        bridge.rebind(to: connection)
    }

    public func startDraining() {
        guard drain == nil else { return }
        let pump = pump
        let retiring = retiring
        self.retiring = nil
        drain = Task {
            await retiring?.value
            await pump.run()
        }
    }

    public func stopDraining() {
        drain?.cancel()
        retiring = drain
        drain = nil
    }

    public func detachFromHost() {
        view.removeFromSuperview()
    }

    public func installJobAlerts(_ delivery: (any NotificationScheduler)?) {
        guard let delivery else { return }
        let alerts = OSCJobAlertEngine(sessionID: sessionID, scheduler: delivery)
        registerOSC(code: 9, alerts: alerts)
        registerOSC(code: 777, alerts: alerts)
        registerOSC(code: 133, alerts: alerts)
    }

    private func registerOSC(code: Int, alerts: OSCJobAlertEngine) {
        engine.registerOSCHandler(code: code) { payload in
            alerts.handle(code: code, payload: payload)
        }
    }
}
