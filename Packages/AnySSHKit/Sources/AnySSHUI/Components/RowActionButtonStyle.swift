import SwiftUI

public struct RowActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    private let tint: Color

    public init(tint: Color = Theme.accent) {
        self.tint = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Text.body)
            .foregroundStyle(isEnabled ? tint : Theme.text.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
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
                Button("Test Connection") {}
                    .buttonStyle(.rowAction)
                Button("Save Key") {}
                    .buttonStyle(.rowAction)
                    .disabled(true)
                Button("Discard") {}
                    .buttonStyle(.rowAction(tint: Theme.destructive))
            }
            .listRowBackground(Theme.surface.raised)
        }
        .scrollContentBackground(.hidden)
    }
}
