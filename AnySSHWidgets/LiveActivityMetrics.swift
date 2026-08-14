import AnySSHUI
import CoreGraphics

@MainActor
enum LiveActivityMetrics {
    static let lockScreenMark: CGFloat = 34
    static let expandedMark: CGFloat = 26
    static let compactMark: CGFloat = Theme.Space.iconGlyph
    static let markRadiusScale: CGFloat = 0.26
    static let staleOpacity: CGFloat = 0.55
}
