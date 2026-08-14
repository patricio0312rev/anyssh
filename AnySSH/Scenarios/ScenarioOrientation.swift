#if canImport(UIKit)
import UIKit

@MainActor
enum ScenarioOrientation {
    static func requestLandscape() {
        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first
        else { return }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
    }
}
#endif
