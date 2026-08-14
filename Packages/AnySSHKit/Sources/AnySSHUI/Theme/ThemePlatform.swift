#if canImport(UIKit)
import UIKit

extension Theme {
    public enum Platform {
        public static let surfaceBase = UIColor.systemBackground
        public static let surfaceRaised = UIColor.secondarySystemBackground
        public static let surfaceOverlay = UIColor.tertiarySystemBackground
        public static let textPrimary = UIColor.label
        public static let textSecondary = UIColor.secondaryLabel
        public static let separator = UIColor.separator
        public static let accent = UIColor.srgb(Theme.accentHex)
    }
}
#endif
