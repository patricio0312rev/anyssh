#if canImport(UIKit)
import AnySSHCore
import SwiftUI
import TerminalEmulator

public struct GestureSettingsView: View {
    @State private var model: GestureSettingsModel

    public init(directory: URL) {
        _model = State(wrappedValue: GestureSettingsModel(directory: directory))
    }

    public var body: some View {
        List {
            bindings
            reset
        }
        .catalogListSurface()
        .navigationTitle("Gestures")
        .accessibilityIdentifier(UIIdentifier.Settings.gesturesScreen)
    }

    private var bindings: some View {
        Section {
            ForEach(GestureSlot.allCases, id: \.self) { slot in
                GestureBindingRow(
                    slot: slot,
                    binding: model.binding(for: slot),
                    bind: { model.bind($0, to: slot) }
                )
                .catalogRowChrome()
            }
        } header: {
            SectionLabel("Bindings")
        } footer: {
            SectionCaption("Swipe left or right to switch sessions. Unbound leaves the swipe unused.")
        }
    }

    private var reset: some View {
        Section {
            Button("Reset to Defaults", action: model.reset)
                .buttonStyle(.rowAction(tint: Theme.destructive))
                .accessibilityIdentifier(UIIdentifier.Settings.gesturesReset)
                .catalogActionRowChrome()
        } footer: {
            if let failure = model.saveFailure {
                SectionCaption(failure, tone: Theme.destructive)
            } else {
                SectionCaption("Restores every gesture to what this build ships with.")
            }
        }
    }
}

#Preview("GestureSettingsView") {
    ThemedRoot {
        NavigationStack {
            GestureSettingsView(directory: URL.temporaryDirectory.appending(path: "gestures"))
        }
    }
}
#endif
