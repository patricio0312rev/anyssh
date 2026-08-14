import SwiftUI

public struct SurfacePalette: Sendable {
    public let base: Color
    public let raised: Color
    public let overlay: Color

    public init() {
        #if canImport(UIKit)
        base = Color(uiColor: .systemBackground)
        raised = Color(uiColor: .secondarySystemBackground)
        overlay = Color(uiColor: .tertiarySystemBackground)
        #else
        base = Color(nsColor: .windowBackgroundColor)
        raised = Color(nsColor: .controlBackgroundColor)
        overlay = Color(nsColor: .underPageBackgroundColor)
        #endif
    }
}
