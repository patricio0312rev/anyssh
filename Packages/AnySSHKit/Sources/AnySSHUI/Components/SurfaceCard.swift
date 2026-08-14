import SwiftUI

public struct SurfaceCard<Content: View>: View {
    private let isSelected: Bool
    private let content: Content

    public init(isSelected: Bool = false, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.content = content()
    }

    public var body: some View {
        content
            .padding(Theme.Space.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface.raised, in: shape)
            .overlay {
                if isSelected { shape.stroke(Theme.accent, lineWidth: 1.5) }
            }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.Space.cardRadius, style: .continuous)
    }
}

#Preview("SurfaceCard") {
    ThemedRoot {
        VStack(spacing: Theme.Space.rowGap) {
            SurfaceCard {
                PrimaryTitle("Plain card")
            }
            SurfaceCard(isSelected: true) {
                PrimaryTitle("Selected card")
            }
        }
        .padding(Theme.Space.screenMargin)
    }
}
