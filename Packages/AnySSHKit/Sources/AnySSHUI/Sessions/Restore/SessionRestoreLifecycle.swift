import SwiftUI

public struct SessionRestoreLifecycle: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    private let model: SessionWorkspaceModel
    private let coordinator: SessionRestoreCoordinator

    public init(model: SessionWorkspaceModel, coordinator: SessionRestoreCoordinator) {
        self.model = model
        self.coordinator = coordinator
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                coordinator.start(source: model)
            }
            .onChange(of: model.registry) { _, registry in
                coordinator.registryDidChange(registry)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    coordinator.handleBackground()
                }
            }
    }
}

extension View {
    public func sessionRestoreLifecycle(
        model: SessionWorkspaceModel,
        coordinator: SessionRestoreCoordinator
    ) -> some View {
        modifier(SessionRestoreLifecycle(model: model, coordinator: coordinator))
    }
}
