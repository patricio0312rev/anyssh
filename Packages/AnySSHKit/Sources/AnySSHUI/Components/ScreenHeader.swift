import SwiftUI

public struct ScreenHeader<Actions: View>: View {
    private let title: String
    private let actions: Actions

    public init(_ title: String, @ViewBuilder actions: () -> Actions = { EmptyView() }) {
        self.title = title
        self.actions = actions()
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.step3) {
            Text(title)
                .font(Theme.Text.screenTitle)
                .foregroundStyle(Theme.text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: Theme.Space.step3)
            HStack(spacing: Theme.Space.step2) { actions }
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] }
        }
        .padding(.horizontal, Theme.Space.screenMargin)
        .padding(.vertical, Theme.Space.step2)
        .frame(maxWidth: .infinity)
        .background(Theme.surface.base)
    }
}

#Preview("ScreenHeader") {
    ThemedRoot {
        VStack(spacing: Theme.Space.step5) {
            ScreenHeader("Hosts") {
                IconButton(systemImage: "gearshape", label: "Settings", surface: .inline) {}
                IconButton(systemImage: "plus", label: "Add host", surface: .inline) {}
            }
            ScreenHeader("Settings")
        }
    }
}
