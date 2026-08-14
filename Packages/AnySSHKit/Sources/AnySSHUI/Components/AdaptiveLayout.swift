import SwiftUI

public enum AdaptiveLayout: Sendable {
    case compact
    case regular

    public init(horizontal: UserInterfaceSizeClass?, vertical: UserInterfaceSizeClass?) {
        self = horizontal == .regular && vertical == .regular ? .regular : .compact
    }

    public var isRegular: Bool { self == .regular }

    public func sidebarVisibility(for width: CGFloat) -> NavigationSplitViewVisibility {
        guard isRegular else { return .all }
        return width < 620 ? .detailOnly : .all
    }
}

public struct AdaptiveLayoutReader<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private let content: (AdaptiveLayout) -> Content

    public init(@ViewBuilder content: @escaping (AdaptiveLayout) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(AdaptiveLayout(horizontal: horizontalSizeClass, vertical: verticalSizeClass))
    }
}

#Preview("AdaptiveLayout") {
    ThemedRoot {
        AdaptiveLayoutReader { layout in
            SurfaceCard {
                PrimaryTitle(layout.isRegular ? "Regular width" : "Compact width")
            }
            .padding(Theme.Space.screenMargin)
        }
    }
}
