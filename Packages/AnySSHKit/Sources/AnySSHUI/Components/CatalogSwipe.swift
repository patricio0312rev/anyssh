import SwiftUI

public enum CatalogSwipe {
    public static func destructive(
        title: String,
        systemImage: String,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: .destructive, action: action) {
            Label(title, systemImage: systemImage)
        }
        .tint(Theme.destructive)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    public static func accent(
        title: String,
        systemImage: String,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .tint(Theme.accent)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#Preview("CatalogSwipe") {
    ThemedRoot {
        List {
            CatalogRow(
                title: "build-box",
                subtitle: "swipe either edge",
                accessibilityIdentifier: "preview.swipe.row"
            )
            .catalogRowChrome()
            .swipeActions(edge: .trailing) {
                CatalogSwipe.destructive(
                    title: "Delete",
                    systemImage: "trash",
                    accessibilityIdentifier: "preview.swipe.delete"
                ) {}
            }
            .swipeActions(edge: .leading) {
                CatalogSwipe.accent(
                    title: "Edit",
                    systemImage: "pencil",
                    accessibilityIdentifier: "preview.swipe.edit"
                ) {}
            }
        }
        .catalogListSurface()
    }
}
