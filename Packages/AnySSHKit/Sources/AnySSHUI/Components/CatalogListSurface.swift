import SwiftUI

extension View {
    public func catalogListSurface() -> some View {
        listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background { Theme.surface.base.ignoresSafeArea() }
            .contentMargins(.horizontal, Theme.Space.screenMargin, for: .scrollContent)
            .contentMargins(.top, Theme.Space.rowGap, for: .scrollContent)
    }

    public func catalogRowChrome(selected: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Space.cardRadius, style: .continuous)
        return listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(Theme.Space.cardPadding)
            .background(Theme.surface.raised, in: shape)
            .overlay {
                if selected { shape.stroke(Theme.accent, lineWidth: 1.5) }
            }
            .modifier(ReorderGutter())
            .listRowInsets(
                EdgeInsets(
                    top: Theme.Space.step1,
                    leading: 0,
                    bottom: Theme.Space.step1,
                    trailing: 0
                )
            )
    }
}

private struct ReorderGutter: ViewModifier {
    #if canImport(UIKit)
    @Environment(\.editMode) private var editMode

    func body(content: Content) -> some View {
        content.padding(
            .trailing,
            editMode?.wrappedValue.isEditing == true ? Theme.Space.step6 : 0
        )
    }
    #else
    func body(content: Content) -> some View { content }
    #endif
}

#Preview("CatalogListSurface") {
    ThemedRoot {
        List {
            CatalogRow(
                title: "build-box",
                subtitle: "deploy@build.internal",
                accessibilityIdentifier: "preview.list.row1"
            )
            .catalogRowChrome()
            CatalogRow(
                title: "edge-01",
                subtitle: "root@10.0.0.7",
                accessibilityIdentifier: "preview.list.row2"
            )
            .catalogRowChrome(selected: true)
            CatalogRow(
                title: "db-primary",
                subtitle: "postgres@10.0.0.9",
                accessibilityIdentifier: "preview.list.row3"
            )
            .catalogRowChrome()
        }
        .catalogListSurface()
    }
}
