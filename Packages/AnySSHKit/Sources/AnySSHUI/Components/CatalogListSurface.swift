import SwiftUI

extension View {
    public func catalogListSurface() -> some View {
        listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background { Theme.surface.base.ignoresSafeArea() }
            .contentMargins(.horizontal, Theme.Space.screenMargin, for: .scrollContent)
            .contentMargins(.top, Theme.Space.rowGap, for: .scrollContent)
            .modifier(SectionSpacing())
    }

    public func catalogRowChrome(selected: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Space.cardRadius, style: .continuous)
        return padding(Theme.Space.cardPadding)
            .background(Theme.surface.raised, in: shape)
            .overlay {
                if selected { shape.stroke(Theme.accent, lineWidth: 1.5) }
            }
            .modifier(ReorderGutter())
            .catalogRowPlain()
    }

    public func catalogActionRowChrome() -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Space.cardRadius, style: .continuous)
        return background(Theme.surface.raised, in: shape)
            .environment(\.rowActionInset, Theme.Space.cardPadding)
            .catalogRowPlain()
    }

    public func catalogRowPlain() -> some View {
        listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
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

private enum RowActionInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var rowActionInset: CGFloat {
        get { self[RowActionInsetKey.self] }
        set { self[RowActionInsetKey.self] = newValue }
    }
}

private struct SectionSpacing: ViewModifier {
    #if canImport(UIKit)
    func body(content: Content) -> some View {
        content.listSectionSpacing(Theme.Space.step3)
    }
    #else
    func body(content: Content) -> some View { content }
    #endif
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
            Button("Reset to Defaults") {}
                .buttonStyle(.rowAction(tint: Theme.destructive))
                .catalogActionRowChrome()
        }
        .catalogListSurface()
    }
}
