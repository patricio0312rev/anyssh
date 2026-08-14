import AnySSHCore
import Foundation
import Observation
import TerminalEmulator

@Observable
@MainActor
public final class AccessoryBarModel {
    public private(set) var layout: AccessoryLayout
    public private(set) var input: TerminalInput
    public private(set) var bindings: MuxKeyBindings?
    public private(set) var lastBytes = [UInt8]()
    public private(set) var persistenceError: String?
    public private(set) var transportError: String?

    private let directory: URL?
    private let writer: (any DisplayWriter)?
    private var repeatingTask: Task<Void, Never>?

    public init(
        layout: AccessoryLayout = .defaults,
        input: TerminalInput = TerminalInput(),
        directory: URL? = nil,
        writer: (any DisplayWriter)? = nil,
        bindings: MuxKeyBindings? = nil
    ) {
        self.layout = layout
        self.input = input
        self.directory = directory
        self.writer = writer
        self.bindings = bindings
    }

    public convenience init(
        directory: URL,
        input: TerminalInput = TerminalInput(),
        writer: (any DisplayWriter)? = nil,
        bindings: MuxKeyBindings? = nil
    ) {
        self.init(
            layout: AccessoryLayout.load(from: directory).ensuringPrefixKey(),
            input: input,
            directory: directory,
            writer: writer,
            bindings: bindings
        )
    }

    public convenience init(
        remoteStoreLocation: URL,
        input: TerminalInput = TerminalInput(),
        writer: (any DisplayWriter)? = nil,
        bindings: MuxKeyBindings? = nil
    ) {
        self.init(
            layout: AccessoryLayout.load(for: remoteStoreLocation).ensuringPrefixKey(),
            input: input,
            directory: AccessoryLayout.directory(for: remoteStoreLocation),
            writer: writer,
            bindings: bindings
        )
    }

    public func updateBindings(_ newBindings: MuxKeyBindings?) {
        bindings = newBindings
    }

    public func activate(_ binding: AccessoryLayout.Binding) async {
        var next = input
        let bytes = AccessoryAction(binding).bytes(
            using: &next,
            prefixChordText: MuxPrefix.chordText(bindings)
        )
        input = next
        lastBytes = bytes
        guard !bytes.isEmpty, let writer else { return }
        do {
            try await writer.send(bytes[...])
            transportError = nil
        } catch {
            transportError = String(describing: error)
        }
    }

    public func applyLatch(to bytes: ArraySlice<UInt8>) -> [UInt8] {
        let modifiers = input.latch.pending
        guard !modifiers.isEmpty else { return Array(bytes) }
        let text = String(decoding: bytes, as: UTF8.self)
        guard text.count == 1, let character = text.first else { return Array(bytes) }
        var next = input
        let encoded = next.send(.character(character), modifiers: modifiers)
        next.clearLatch()
        input = next
        return encoded
    }

    public func title(for key: AccessoryLayout.Key) -> String {
        let action = AccessoryAction(key.tap)
        if case .prefix = action { return "PRE" }
        if case .chord = action { return action.label ?? key.label }
        return key.label
    }

    static func prefixLabel(_ bindings: MuxKeyBindings?) -> String {
        let text = MuxPrefix.chordText(bindings)
        return (try? Chord(parsing: text))?.label ?? text
    }

    public func move(id: String, before targetID: String?) {
        layout = layout.moved(id: id, before: targetID)
        save()
    }

    public func add(_ key: AccessoryLayout.Key) {
        layout = layout.adding(key)
        save()
    }

    public func remove(id: String) {
        layout = layout.removing(id: id)
        save()
    }

    public func reset() {
        layout = .defaults
        input.clearLatch()
        save()
    }

    public func startRepeating(_ binding: AccessoryLayout.Binding) {
        stopRepeating()
        repeatingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(80))
                } catch {
                    return
                }
                guard let self, !Task.isCancelled else { return }
                await self.activate(binding)
            }
        }
    }

    public func stopRepeating() {
        repeatingTask?.cancel()
        repeatingTask = nil
    }

    private func save() {
        guard let directory else { return }
        do {
            try layout.save(to: directory)
            persistenceError = nil
        } catch {
            persistenceError = String(describing: error)
        }
    }
}
