import SwiftUI

public struct SegmentedPicker<Value: Hashable>: View {
    public struct Option: Identifiable {
        public let id: String
        public let label: String
        public let value: Value

        public init(id: String, label: String, value: Value) {
            self.id = id
            self.label = label
            self.value = value
        }
    }

    private let options: [Option]
    private let selection: Value
    private let accessibilityIdentifier: (Option) -> String
    private let select: (Value) -> Void

    public init(
        options: [Option],
        selection: Value,
        accessibilityIdentifier: @escaping (Option) -> String,
        select: @escaping (Value) -> Void
    ) {
        self.options = options
        self.selection = selection
        self.accessibilityIdentifier = accessibilityIdentifier
        self.select = select
    }

    public var body: some View {
        HStack(spacing: Theme.Space.step2) {
            ForEach(options) { option in
                segment(option)
            }
        }
    }

    private func segment(_ option: Option) -> some View {
        let isSelected = option.value == selection
        return Button {
            select(option.value)
        } label: {
            Text(option.label)
                .font(Theme.Text.body)
                .foregroundStyle(isSelected ? Theme.text.primary : Theme.text.secondary)
                .lineLimit(1)
                .padding(.horizontal, Theme.Space.step3)
                .frame(minHeight: Theme.Buttons.height)
                .background(Theme.surface.raised, in: Capsule())
                .overlay {
                    if isSelected { Capsule().strokeBorder(Theme.accent, lineWidth: 1.5) }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected ? "selected" : "")
        .accessibilityIdentifier(accessibilityIdentifier(option))
    }
}

#Preview("SegmentedPicker") {
    @Previewable @State var layout = "list"
    let options = [
        SegmentedPicker<String>.Option(id: "list", label: "List", value: "list"),
        SegmentedPicker<String>.Option(id: "accordion", label: "Accordion", value: "accordion"),
        SegmentedPicker<String>.Option(id: "grid", label: "Grid", value: "grid"),
    ]
    return ThemedRoot {
        SegmentedPicker(
            options: options,
            selection: layout,
            accessibilityIdentifier: { "preview.segment.\($0.id)" },
            select: { layout = $0 }
        )
        .padding(Theme.Space.screenMargin)
    }
}
