import SwiftUI

public struct AccentCapsuleButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Text.body)
            .foregroundStyle(Color.white)
            .padding(.horizontal, Theme.Space.step4)
            .frame(minHeight: Theme.Buttons.height)
            .background(configuration.isPressed ? Theme.accentPressed : Theme.accent, in: Capsule())
    }
}

extension ButtonStyle where Self == AccentCapsuleButtonStyle {
    public static var accentCapsule: AccentCapsuleButtonStyle { AccentCapsuleButtonStyle() }
}

#Preview("AccentCapsuleButtonStyle") {
    ThemedRoot {
        VStack(spacing: Theme.Space.step3) {
            Button("Add Host") {}
                .buttonStyle(.accentCapsule)
            Button("Import Key") {}
                .buttonStyle(.raised)
        }
        .padding(Theme.Space.screenMargin)
    }
}
