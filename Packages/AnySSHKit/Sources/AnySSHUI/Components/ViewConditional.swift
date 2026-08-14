import SwiftUI

extension View {
    @ViewBuilder
    public func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition { transform(self) } else { self }
    }
}

#Preview("ViewConditional") {
    @Previewable @State var isDraggable = true
    return ThemedRoot {
        VStack(spacing: Theme.Space.step3) {
            SurfaceCard {
                PrimaryTitle(isDraggable ? "Drag gesture attached" : "No gesture attached")
            }
            .if(isDraggable) { card in
                card.gesture(DragGesture())
            }
            Button("Toggle") { isDraggable.toggle() }
                .buttonStyle(.glass)
        }
        .padding(Theme.Space.screenMargin)
    }
}
