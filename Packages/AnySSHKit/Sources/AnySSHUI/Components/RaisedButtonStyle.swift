import SwiftUI

public struct RaisedButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Text.body)
            .foregroundStyle(Theme.text.primary)
            .padding(.horizontal, Theme.Space.step4)
            .frame(minHeight: Theme.Buttons.height)
            .background(Theme.surface.raised, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == RaisedButtonStyle {
    public static var raised: RaisedButtonStyle { RaisedButtonStyle() }
}

#Preview("RaisedButtonStyle") {
    ThemedRoot {
        VStack(spacing: Theme.Space.step3) {
            Button("Import Key") {}
                .buttonStyle(.raised)
            Button("Add Host") {}
                .buttonStyle(.accentCapsule)
        }
        .padding(Theme.Space.screenMargin)
    }
}
