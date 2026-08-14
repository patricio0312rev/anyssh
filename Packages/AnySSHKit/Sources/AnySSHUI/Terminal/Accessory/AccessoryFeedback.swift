#if canImport(UIKit)
import UIKit

@MainActor
enum AccessoryFeedback {
    private static let generator = UIImpactFeedbackGenerator(style: .light)

    static func tap() {
        generator.impactOccurred(intensity: 0.7)
        generator.prepare()
    }
}
#else
enum AccessoryFeedback {
    static func tap() {}
}
#endif
