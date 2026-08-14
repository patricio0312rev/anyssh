import CoreGraphics
import Foundation

public enum ImageComparisonMode: String, CaseIterable, Sendable {
    case twoUp
    case swipe
    case onionSkin
}

public struct ImageComparisonSize: Equatable, Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

public struct ImageComparisonLayout: Equatable, Sendable {
    public let before: ImageComparisonSize
    public let after: ImageComparisonSize
    public let union: ImageComparisonSize

    public init(before: ImageComparisonSize, after: ImageComparisonSize) {
        self.before = before
        self.after = after
        union = ImageComparisonSize(
            width: max(before.width, after.width),
            height: max(before.height, after.height)
        )
    }

    public var dimensionDeltaLabel: String {
        "\(before.width) × \(before.height) → \(after.width) × \(after.height) "
            + "(Δ \(after.width - before.width) × \(after.height - before.height))"
    }
}

public enum ImageComparisonLayoutBuilder {
    public static func layout(before: CGImage, after: CGImage) -> ImageComparisonLayout {
        ImageComparisonLayout(
            before: ImageComparisonSize(width: before.width, height: before.height),
            after: ImageComparisonSize(width: after.width, height: after.height)
        )
    }
}
