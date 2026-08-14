import SwiftUI

enum FileBrowserMetrics {
    static let parallax: CGFloat = 60
    static let closeThreshold: CGFloat = 90
    static let dragMinimum: CGFloat = 24

    static let pageChange: Animation = .smooth(duration: 0.3)
    static let dragSettle: Animation = .smooth(duration: 0.2)
    static let renderingSwap: Animation = .smooth(duration: 0.24)
}
