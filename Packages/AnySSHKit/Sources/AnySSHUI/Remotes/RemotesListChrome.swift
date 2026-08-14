import AnySSHCore
import SwiftUI

extension View {
    func remotesChrome(
        isReordering: Binding<Bool>,
        canAdd: Bool,
        canReorder: Bool,
        add: @escaping () -> Void
    ) -> some View {
        #if canImport(UIKit)
        return toolbar {
            ToolbarItem(placement: .primaryAction) {
                if canAdd {
                    Button("Add Host", systemImage: "plus", action: add)
                        .tint(Theme.text.primary)
                        .accessibilityIdentifier(UIIdentifier.Remote.add)
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                if canReorder {
                    Button(isReordering.wrappedValue ? "Done" : "Reorder") {
                        isReordering.wrappedValue.toggle()
                    }
                    .accessibilityIdentifier(UIIdentifier.Remote.edit)
                }
            }
        }
        .environment(\.editMode, .constant(isReordering.wrappedValue ? .active : .inactive))
        #else
        return toolbar {
            ToolbarItem(placement: .primaryAction) {
                if canAdd {
                    Button("Add Host", action: add)
                        .accessibilityIdentifier(UIIdentifier.Remote.add)
                }
            }
        }
        #endif
    }

    func remoteSecretRefusal(
        _ refusal: SecretsErrorState?,
        dismiss: @escaping () -> Void
    ) -> some View {
        let state = refusal.map(ErrorState.secrets)
        return alert(
            state?.copy.title ?? "",
            isPresented: Binding(get: { state != nil }, set: { if !$0 { dismiss() } }),
            presenting: state
        ) { presented in
            Button(presented.copy.recoveryLabel, action: dismiss)
                .accessibilityIdentifier(presented.accessibilityIdentifier)
        } message: { presented in
            Text(presented.copy.body)
        }
    }
}
