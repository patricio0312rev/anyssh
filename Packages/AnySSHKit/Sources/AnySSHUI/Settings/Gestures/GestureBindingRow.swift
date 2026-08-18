#if canImport(UIKit)
import AnySSHCore
import SwiftUI
import TerminalEmulator

struct GestureBindingRow: View {
    let slot: GestureSlot
    let binding: GestureLayout.Binding?
    let bind: (GestureLayout.Binding?) -> Void

    var body: some View {
        CatalogRow(
            title: slot.title,
            subtitle: GestureActionCatalogue.title(of: binding),
            titleLineLimit: 1,
            accessibilityIdentifier: UIIdentifier.Settings.gestureRow(slot.rawValue),
            leading: { EmptyView() },
            trailing: { menu },
            footer: { EmptyView() }
        )
    }

    private var menu: some View {
        Menu {
            Button("Unbound") { bind(nil) }
            ForEach(GestureActionCatalogue.groups, id: \.self) { group in
                Section(group) {
                    ForEach(GestureActionCatalogue.actions(in: group)) { action in
                        Button(action.title) {
                            bind(GestureLayout.Binding(kind: action.kind, value: action.value))
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "chevron.up.chevron.down")
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
                .frame(width: Theme.Buttons.iconHitTarget, height: Theme.Buttons.iconHitTarget)
                .contentShape(.rect)
        }
        .accessibilityLabel("Change what \(slot.title) does")
    }
}

#Preview("GestureBindingRow") {
    ThemedRoot {
        List {
            GestureBindingRow(
                slot: .swipeLeft,
                binding: GestureLayout.defaults.binding(for: GestureSlot.swipeLeft.rawValue),
                bind: { _ in }
            )
            .catalogRowChrome()
            GestureBindingRow(slot: .swipeRight, binding: nil, bind: { _ in })
                .catalogRowChrome()
        }
        .catalogListSurface()
    }
}
#endif
