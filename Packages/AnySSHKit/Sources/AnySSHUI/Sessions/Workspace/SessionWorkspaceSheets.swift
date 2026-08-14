#if canImport(UIKit)
import SwiftUI

extension View {
    func workspaceSheets(
        model: SessionWorkspaceModel,
        isMultiplexerPresented: Binding<Bool>,
        isJumpToPresented: Binding<Bool>,
        isJobAlertsPresented: Binding<Bool>
    ) -> some View {
        self
            .sheet(isPresented: isJobAlertsPresented) {
                JobAlertSettingsView(settings: model.jobAlertSettings)
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: authPresented(model)) {
                if let bridge = model.activeAuthBridge {
                    AuthPromptSheet(model: bridge.auth)
                        .interactiveDismissDisabled()
                }
            }
            .sheet(isPresented: trustPresented(model)) {
                if let bridge = model.activeAuthBridge {
                    HostKeyTrustView(model: bridge.trust)
                }
            }
            .sheet(isPresented: savePasswordPresented(model)) {
                AuthSavePasswordSheet(
                    onSave: { Task { await model.activeAuthBridge?.savePendingPassword() } },
                    onSkip: { model.activeAuthBridge?.dismissPasswordSave() }
                )
                .presentationDetents([.height(AuthSavePasswordSheet.detentHeight)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: isMultiplexerPresented) {
                if let adapter = model.activeMultiplexerAdapter {
                    MultiplexerPaneListView(
                        adapter: adapter,
                        writer: model.activeSessionID.flatMap { model.connection(for: $0) },
                        onDismiss: { isMultiplexerPresented.wrappedValue = false }
                    )
                }
            }
            .sheet(isPresented: isJumpToPresented) {
                if let adapter = model.activeMultiplexerAdapter {
                    JumpToSheet(
                        model: JumpToModel(
                            adapter: adapter,
                            directory: model.layoutDirectory,
                            writer: model.activeSessionID.flatMap { model.connection(for: $0) }
                        ),
                        onDismiss: { isJumpToPresented.wrappedValue = false }
                    )
                }
            }
    }

    private func authPresented(_ model: SessionWorkspaceModel) -> Binding<Bool> {
        Binding(get: { model.activeAuthBridge?.auth.round != nil }, set: { _ in })
    }

    private func trustPresented(_ model: SessionWorkspaceModel) -> Binding<Bool> {
        Binding(
            get: {
                if case .asking = model.activeAuthBridge?.trust.stage { return true }
                return false
            },
            set: { _ in }
        )
    }

    private func savePasswordPresented(_ model: SessionWorkspaceModel) -> Binding<Bool> {
        Binding(
            get: { model.activeAuthBridge?.pendingPasswordSave != nil },
            set: { if !$0 { model.activeAuthBridge?.dismissPasswordSave() } }
        )
    }
}
#endif
