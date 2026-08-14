import SwiftUI

public struct WrapToggle: View {
    @Binding private var wrapsLines: Bool

    public init(wrapsLines: Binding<Bool>) {
        _wrapsLines = wrapsLines
    }

    public var body: some View {
        IconButton(
            systemImage: wrapsLines ? "arrow.turn.down.left" : "arrow.left.and.right",
            label: wrapsLines ? "Stop wrapping lines" : "Wrap lines",
            surface: .inline,
            accessibilityIdentifier: UIIdentifier.Workspace.wrapToggle
        ) {
            withAnimation(Theme.Motion.standard) { wrapsLines.toggle() }
        }
    }
}

#Preview("WrapToggle") {
    @Previewable @State var wrapsLines = true
    return ThemedRoot {
        VStack(spacing: Theme.Space.step3) {
            WrapToggle(wrapsLines: $wrapsLines)
            Text(wrapsLines ? "Wrapping" : "Not wrapping")
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
        }
    }
}
