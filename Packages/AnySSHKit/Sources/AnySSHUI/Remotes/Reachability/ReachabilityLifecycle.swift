import SwiftUI

public struct ReachabilityLifecycle: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    private let model: ReachabilityStatusModel

    public init(model: ReachabilityStatusModel) {
        self.model = model
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                model.start()
            }
            .onDisappear {
                model.stop()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await model.applicationDidBecomeActive() }
            }
    }
}

extension View {
    public func reachabilityLifecycle(_ model: ReachabilityStatusModel) -> some View {
        modifier(ReachabilityLifecycle(model: model))
    }
}
