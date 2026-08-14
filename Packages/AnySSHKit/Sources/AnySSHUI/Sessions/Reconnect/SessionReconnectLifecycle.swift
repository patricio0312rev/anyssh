import SwiftUI

public struct SessionReconnectLifecycle: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    private let model: SessionWorkspaceModel

    public init(model: SessionWorkspaceModel) {
        self.model = model
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                model.startReconnectMonitoring()
            }
            .onDisappear {
                model.stopReconnectMonitoring()
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    model.handleForeground()
                case .background, .inactive:
                    model.handleBackground()
                @unknown default:
                    break
                }
            }
    }
}

extension View {
    public func sessionReconnectLifecycle(_ model: SessionWorkspaceModel) -> some View {
        modifier(SessionReconnectLifecycle(model: model))
    }
}
