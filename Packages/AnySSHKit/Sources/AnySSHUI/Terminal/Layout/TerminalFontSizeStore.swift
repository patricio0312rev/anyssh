import CoreGraphics
import Foundation

public struct TerminalFontSizeStore: Sendable {
    public static let defaultsKey = "terminal.fontSize"
    public static let defaultSize: CGFloat = 13
    public static let minimum: CGFloat = 8
    public static let maximum: CGFloat = 32

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> CGFloat {
        guard defaults.object(forKey: Self.defaultsKey) != nil else { return Self.defaultSize }
        return Self.clamped(CGFloat(defaults.double(forKey: Self.defaultsKey)))
    }

    public func save(_ size: CGFloat) {
        defaults.set(Double(Self.clamped(size)), forKey: Self.defaultsKey)
    }

    public static func clamped(_ size: CGFloat) -> CGFloat {
        min(maximum, max(minimum, size))
    }

    public static func size(base: CGFloat, scale: CGFloat) -> CGFloat {
        clamped(base * scale)
    }
}
