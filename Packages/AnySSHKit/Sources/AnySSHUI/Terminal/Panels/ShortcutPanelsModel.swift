import AnySSHCore
import Foundation
import Observation
import TerminalEmulator

@MainActor
@Observable
public final class ShortcutPanelsModel {
    public enum DetachOutcome: Sendable {
        case sent(scope: ShortcutPanel.Scope)
        case sendFailed
    }

    public private(set) var layout: ShortcutPanelLayout
    public private(set) var selectedScope: ShortcutPanel.Scope
    public private(set) var lastBytes = [UInt8]()
    public private(set) var persistenceError: String?
    public private(set) var transportError: String?
    public var onDetach: (@MainActor (DetachOutcome) -> Void)?

    private let directory: URL?
    private let writer: (any DisplayWriter)?

    public init(
        layout: ShortcutPanelLayout = ShortcutPanelDefaults.standard,
        kind: MultiplexerKind = .none,
        capabilities: HostCapabilities? = nil,
        bindings: MuxKeyBindings? = nil,
        directory: URL? = nil,
        writer: (any DisplayWriter)? = nil
    ) {
        let built = ShortcutPanelBuilder.make(
            kind: kind,
            capabilities: capabilities,
            bindings: bindings,
            persisted: layout
        )
        self.directory = directory
        self.writer = writer
        self.layout = built
        selectedScope = built.panels.first?.scope ?? .custom
    }

    public convenience init(
        directory: URL,
        kind: MultiplexerKind = .none,
        capabilities: HostCapabilities? = nil,
        bindings: MuxKeyBindings? = nil,
        writer: (any DisplayWriter)? = nil
    ) {
        self.init(
            layout: ShortcutPanelLayout.load(from: directory),
            kind: kind,
            capabilities: capabilities,
            bindings: bindings,
            directory: directory,
            writer: writer
        )
    }

    public convenience init(
        remoteStoreLocation: URL,
        kind: MultiplexerKind = .none,
        capabilities: HostCapabilities? = nil,
        bindings: MuxKeyBindings? = nil,
        writer: (any DisplayWriter)? = nil
    ) {
        self.init(
            layout: ShortcutPanelLayout.load(for: remoteStoreLocation),
            kind: kind,
            capabilities: capabilities,
            bindings: bindings,
            directory: ShortcutPanelLayout.directory(for: remoteStoreLocation),
            writer: writer
        )
    }

    public var selectedPanel: ShortcutPanel? {
        layout.panel(scope: selectedScope)
    }

    public var renderedLastBytes: String {
        lastBytes.isEmpty
            ? "[]"
            : "[" + lastBytes.map { String(format: "0x%02x", $0) }.joined(separator: ", ") + "]"
    }

    public func select(_ scope: ShortcutPanel.Scope) {
        guard layout.contains(scope: scope) else { return }
        selectedScope = scope
    }

    public func activate(_ entry: ShortcutPanel.Entry, scope: ShortcutPanel.Scope) async {
        let bytes = entry.payload.bytes()
        lastBytes = bytes
        guard !bytes.isEmpty, let writer else { return }
        do {
            try await writer.send(bytes[...])
            transportError = nil
            if isDetach(entry, scope: scope) {
                onDetach?(.sent(scope: scope))
            }
        } catch {
            transportError = String(describing: error)
            if isDetach(entry, scope: scope) {
                onDetach?(.sendFailed)
            }
        }
    }

    public func save(
        binding: SimpleBinding,
        for entry: ShortcutPanel.Entry,
        scope: ShortcutPanel.Scope
    ) {
        let payload: ShortcutPanel.Entry.Payload
        switch binding {
        case .chord(let chord): payload = .chord(chord.syntaxText)
        case .text(let text): payload = .text(text)
        }
        let label = scope == .custom ? binding.preview : entry.label
        let updated = ShortcutPanel.Entry(id: entry.id, label: label, payload: payload)

        if let panel = layout.panel(scope: scope) {
            layout = layout.replacing(panel.replacing(updated))
        } else if scope == .custom {
            layout = layout.replacing(
                ShortcutPanel(id: "custom", scope: .custom, name: "Custom", entries: [updated])
            )
            selectedScope = .custom
        } else {
            return
        }
        save()
    }

    public func addCustomPanel() {
        guard !layout.contains(scope: .custom) else { return }
        layout = layout.replacing(
            ShortcutPanel(id: "custom", scope: .custom, name: "Custom", entries: [])
        )
        selectedScope = .custom
        save()
    }

    private func isDetach(_ entry: ShortcutPanel.Entry, scope: ShortcutPanel.Scope) -> Bool {
        entry.id == "detach" && (scope == .tmux || scope == .herdr)
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
