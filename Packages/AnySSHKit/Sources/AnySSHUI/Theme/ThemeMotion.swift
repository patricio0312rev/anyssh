import SwiftUI

extension Theme {
    public enum Motion {
        public static let standard: Animation = .default
        public static let spring: Animation = .spring(response: 0.32, dampingFraction: 0.86)
        public static let overlay: Animation = .smooth(duration: 0.28)
        public static let sessionSwitch: Animation = .smooth(duration: 0.3)
        public static let copyFeedbackDwell: Duration = .seconds(1.6)
    }
}
