import SwiftUI
import TerminalEmulator

public struct ClipboardSurface<Content: View>: View {
    @Bindable private var controller: ClipboardController
    @Environment(\.statusToasts) private var statusToasts
    @State private var refusalToastID: UUID?
    private let content: Content

    public init(controller: ClipboardController, @ViewBuilder content: () -> Content) {
        self.controller = controller
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
            ClipboardPasteControl {
                Task { await controller.beginPaste() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .sheet(isPresented: pendingBinding) {
            if let content = controller.confirmationContent {
                PasteConfirmSheet(
                    content: content,
                    confirm: { controller.confirmPaste() },
                    cancel: { controller.cancelPaste() }
                )
                .presentationDetents([.medium])
            }
        }
        .onChange(of: controller.refusal) { _, refusal in
            syncRefusalToast(refusal)
        }
        .onAppear {
            syncRefusalToast(controller.refusal)
        }
        .onDisappear {
            retractRefusalToast()
        }
    }

    private var pendingBinding: Binding<Bool> {
        Binding(
            get: { controller.pendingPaste != nil },
            set: { presented in
                if !presented, controller.pendingPaste != nil {
                    controller.cancelPaste()
                }
            }
        )
    }

    private func syncRefusalToast(_ refusal: ClipboardRefusal?) {
        retractRefusalToast()
        guard let refusal else { return }
        let presentedID = UUID()
        refusalToastID = presentedID
        let toast = StatusToast(
            id: presentedID,
            refusal: refusal,
            dismiss: { [statusToasts] in
                statusToasts.retract(presentedID)
                controller.dismissRefusal()
            }
        )
        _ = statusToasts.present(toast)
    }

    private func retractRefusalToast() {
        guard let id = refusalToastID else { return }
        refusalToastID = nil
        statusToasts.retract(id)
    }
}
