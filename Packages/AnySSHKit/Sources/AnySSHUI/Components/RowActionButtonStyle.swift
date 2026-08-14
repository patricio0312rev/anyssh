import SwiftUI

public struct RowActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.rowActionInset) private var inset

    private let tint: Color

    public init(tint: Color = Theme.text.primary) {
        self.tint = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Text.body)
            .foregroundStyle(isEnabled ? tint : Theme.text.tertiary)
            .frame(maxWidth: .infinity, minHeight: Theme.Buttons.height, alignment: .leading)
            .padding(.horizontal, inset)
            .contentShape(.rect)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == RowActionButtonStyle {
    public static var rowAction: RowActionButtonStyle {
        RowActionButtonStyle()
    }

    public static func rowAction(tint: Color) -> RowActionButtonStyle {
        RowActionButtonStyle(tint: tint)
    }
}

#Preview("RowActionButtonStyle") {
    ThemedRoot {
        Form {
            Section {
                Button {
                } label: {
                    Label("Paste Key", systemImage: "key")
                }
                .buttonStyle(.rowAction)
                Button("Save Key") {}
                    .buttonStyle(.rowAction(tint: Theme.accent))
                    .disabled(true)
                Button("Discard") {}
                    .buttonStyle(.rowAction(tint: Theme.destructive))
            }
            .listRowBackground(Theme.surface.raised)
        }
        .scrollContentBackground(.hidden)
    }
}
