import AnySSHCore
import Foundation
import Observation
import TerminalEmulator

@MainActor
@Observable
public final class GestureSettingsModel {
    public private(set) var layout: GestureLayout
    public private(set) var saveFailure: String?

    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
        layout = GestureLayout.load(from: directory)
    }

    public func binding(for slot: GestureSlot) -> GestureLayout.Binding? {
        layout.binding(for: slot.rawValue)
    }

    public func bind(_ binding: GestureLayout.Binding?, to slot: GestureSlot) {
        persist(layout.setting(binding, for: slot.rawValue))
    }

    public func reset() {
        persist(layout.reset())
    }

    private func persist(_ next: GestureLayout) {
        layout = next
        do {
            try next.save(to: directory)
            saveFailure = nil
        } catch {
            saveFailure = error.localizedDescription
        }
    }
}
