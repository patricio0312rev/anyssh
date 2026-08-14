import SwiftUI

public struct SheetScaffold<Content: View>: View {
    private let title: String
    private let closeIdentifier: String
    private let onClose: (() -> Void)?
    private let content: Content

    public init(
        _ title: String,
        closeIdentifier: String,
        onClose: (() -> Void)?,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.closeIdentifier = closeIdentifier
        self.onClose = onClose
        self.content = content()
    }

    public var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background { Theme.surface.base.ignoresSafeArea() }
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { close }
                }
        }
        .tint(Theme.accent)
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var close: some View {
        if let onClose {
            CloseButton(accessibilityIdentifier: closeIdentifier, action: onClose)
        }
    }
}

#Preview("SheetScaffold") {
    ThemedRoot {
        SheetScaffold("Jump to", closeIdentifier: "preview.close", onClose: {}) {
            List {
                CatalogRow(title: "main", subtitle: "2 panes", accessibilityIdentifier: "p.row")
                    .catalogRowChrome()
            }
            .catalogListSurface()
        }
    }
}
