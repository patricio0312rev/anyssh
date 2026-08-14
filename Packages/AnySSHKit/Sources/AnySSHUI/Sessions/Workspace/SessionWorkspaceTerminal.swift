#if canImport(UIKit)
import AnySSHCore
import SwiftUI

extension SessionWorkspaceView {
    func terminal(_ surface: TerminalSurface) -> some View {
        ZStack(alignment: .top) {
            TerminalHost(
                engine: surface.engine,
                onSessionSwitch: presentSwitcher,
                onGesture: handleGesture,
                commandRegistry: commandRegistry
            )
            .onAppear { model.firstFramePresented(for: surface.sessionID) }
            VStack(spacing: 0) {
                SessionConnectionChrome(
                    failure: model.activeFailure,
                    capabilities: model.activeSurvivalState == nil
                        ? nil
                        : model.activeRecord?.capabilities,
                    reconnectState: model.activeSessionID.flatMap {
                        model.registry.reconnectState(for: $0)
                    },
                    attemptCount: model.activeRecord?.reconnectAttempts ?? 0,
                    canRetry: model.canRetryActiveSession,
                    onRetry: { Task { await model.retryActiveSession() } }
                )
                axByteCounter(surface.bytesReceived)
                axNotificationProbe()
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}
#endif
