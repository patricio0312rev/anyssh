import CoreGraphics

public enum DiffFontScale: Sendable {
    public static let defaultSize: CGFloat = 12
    public static let minimumSize: CGFloat = 8
    public static let maximumSize: CGFloat = 24

    public static func clamped(_ value: CGFloat) -> CGFloat {
        min(maximumSize, max(minimumSize, value))
    }

    public static func magnified(by magnification: CGFloat) -> CGFloat {
        clamped(defaultSize * magnification)
    }
}
