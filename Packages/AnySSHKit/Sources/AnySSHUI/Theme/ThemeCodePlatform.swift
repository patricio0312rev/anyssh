#if canImport(UIKit)
import UIKit

extension Theme.Code {
    public enum Platform {
        public static let canvas = UIColor.srgb(Theme.Code.Hex.canvas)
        public static let foreground = UIColor.srgb(Theme.Code.Hex.foreground)
        public static let selectionHandle = UIColor.srgb(Theme.Code.Hex.purple)
    }
}
#endif
