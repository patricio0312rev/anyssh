import SwiftUI

public struct LoadingView: View {
    public enum Variant {
        case inline
        case screen(label: String)
    }

    private let variant: Variant

    public init(_ variant: Variant) {
        self.variant = variant
    }

    public var body: some View {
        switch variant {
        case .inline:
            spinner(size: .small)
        case .screen(let label):
            VStack(spacing: Theme.Space.step3) {
                spinner(size: .regular)
                Text(label)
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func spinner(size: ControlSize) -> some View {
        ProgressView()
            .controlSize(size)
            .tint(Theme.text.secondary)
    }
}

#Preview("LoadingView") {
    ThemedRoot {
        VStack(spacing: Theme.Space.step5) {
            LoadingView(.inline)
            LoadingView(.screen(label: "Loading hosts"))
        }
        .padding(Theme.Space.screenMargin)
    }
}
