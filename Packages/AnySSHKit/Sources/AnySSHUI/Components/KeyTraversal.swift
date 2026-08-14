import SwiftUI

public struct KeyTraversal: ViewModifier {
    private let onMoveUp: () -> Void
    private let onMoveDown: () -> Void
    private let onActivate: () -> Void
    private let onDismiss: () -> Void

    public init(
        onMoveUp: @escaping () -> Void,
        onMoveDown: @escaping () -> Void,
        onActivate: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onMoveUp = onMoveUp
        self.onMoveDown = onMoveDown
        self.onActivate = onActivate
        self.onDismiss = onDismiss
    }

    public func body(content: Content) -> some View {
        content
            .onKeyPress(.upArrow) {
                onMoveUp()
                return .handled
            }
            .onKeyPress(.downArrow) {
                onMoveDown()
                return .handled
            }
            .onKeyPress(.return) {
                onActivate()
                return .handled
            }
            .onKeyPress(.escape) {
                onDismiss()
                return .handled
            }
    }
}

extension View {
    public func keyTraversal(
        onMoveUp: @escaping () -> Void,
        onMoveDown: @escaping () -> Void,
        onActivate: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(
            KeyTraversal(
                onMoveUp: onMoveUp,
                onMoveDown: onMoveDown,
                onActivate: onActivate,
                onDismiss: onDismiss
            )
        )
    }
}

#Preview("KeyTraversal") {
    @Previewable @State var selection = 0
    let titles = ["build-box", "edge-01", "db-primary"]
    return ThemedRoot {
        VStack(spacing: Theme.Space.rowGap) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                SurfaceCard(isSelected: index == selection) {
                    CatalogRow(title: title, accessibilityIdentifier: "preview.traversal.\(index)")
                }
            }
        }
        .padding(Theme.Space.screenMargin)
        .keyTraversal(
            onMoveUp: { selection = max(0, selection - 1) },
            onMoveDown: { selection = min(titles.count - 1, selection + 1) },
            onActivate: {},
            onDismiss: {}
        )
    }
}
