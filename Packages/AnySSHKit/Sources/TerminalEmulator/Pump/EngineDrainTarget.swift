import AnySSHCore

@MainActor
public final class EngineDrainTarget {
    private let engine: any TerminalEngine
    private let metadata: TerminalMetadataCoalescer
    private let deliverMetadata: TerminalMetadataDelivery

    public init(
        engine: any TerminalEngine,
        metadata: TerminalMetadataCoalescer,
        deliverMetadata: @escaping TerminalMetadataDelivery
    ) {
        self.engine = engine
        self.metadata = metadata
        self.deliverMetadata = deliverMetadata
    }

    public func receive(_ bytes: ArraySlice<UInt8>) {
        engine.feed(bytes)
        guard let snapshot = metadata.flush() else { return }
        deliverMetadata(snapshot)
    }

    public func pump(configuration: PumpConfiguration = .default) -> OutputPump {
        OutputPump(configuration: configuration) { [self] bytes in receive(bytes) }
    }
}
