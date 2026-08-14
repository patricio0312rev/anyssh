import SwiftUI

public struct ThemedRoot<Content: View>: View {
    @State private var statusToasts: StatusToastCenter
    private let content: Content

    public init(
        statusToasts: StatusToastCenter = StatusToastCenter(),
        @ViewBuilder content: () -> Content
    ) {
        _statusToasts = State(initialValue: statusToasts)
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Theme.surface.base.ignoresSafeArea()
            content
        }
        .tint(Theme.accent)
        .foregroundStyle(Theme.text.primary)
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
        .statusToastHost(center: statusToasts)
    }
}
