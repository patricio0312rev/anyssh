import SwiftUI

public struct CatalogRow<Leading: View, Trailing: View, Footer: View>: View {
    public enum Layout {
        case list
        case stacked
    }

    private let title: String
    private let subtitle: String?
    private let subtitleMonospaced: Bool
    private let subtitleLineLimit: Int?
    private let detail: String?
    private let detailAccessibilityIdentifier: String?
    private let titleLineLimit: Int
    private let layout: Layout
    private let accessibilityIdentifier: String
    private let leading: Leading
    private let trailing: Trailing
    private let footer: Footer

    public init(
        title: String,
        subtitle: String? = nil,
        subtitleMonospaced: Bool = false,
        subtitleLineLimit: Int? = nil,
        detail: String? = nil,
        detailAccessibilityIdentifier: String? = nil,
        titleLineLimit: Int = 2,
        layout: Layout = .list,
        accessibilityIdentifier: String,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.subtitle = subtitle
        self.subtitleMonospaced = subtitleMonospaced
        self.subtitleLineLimit = subtitleLineLimit
        self.detail = detail
        self.detailAccessibilityIdentifier = detailAccessibilityIdentifier
        self.titleLineLimit = titleLineLimit
        self.layout = layout
        self.accessibilityIdentifier = accessibilityIdentifier
        self.leading = leading()
        self.trailing = trailing()
        self.footer = footer()
    }

    public var body: some View {
        HStack(alignment: rowAlignment, spacing: Theme.Space.step3) {
            leading
            textColumn
            if layout == .list {
                Spacer(minLength: 0)
                trailing
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var textColumn: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step1) {
            PrimaryTitle(title, lineLimit: titleLineLimit)
            if let subtitle {
                Text(subtitle)
                    .font(subtitleMonospaced ? Theme.code() : Theme.Text.caption)
                    .foregroundStyle(Theme.text.secondary)
                    .lineLimit(subtitleLineLimit ?? (layout == .stacked ? 1 : 2))
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let detail {
                detailText(detail)
            }
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func detailText(_ detail: String) -> some View {
        let text = Text(detail)
            .font(Theme.Text.caption)
            .foregroundStyle(Theme.text.tertiary)
            .lineLimit(2)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
        if let detailAccessibilityIdentifier {
            text.accessibilityIdentifier(detailAccessibilityIdentifier)
        } else {
            text
        }
    }

    private var rowAlignment: VerticalAlignment {
        layout == .stacked ? .top : .center
    }
}

extension CatalogRow where Leading == EmptyView, Trailing == EmptyView, Footer == EmptyView {
    public init(
        title: String,
        subtitle: String? = nil,
        subtitleMonospaced: Bool = false,
        subtitleLineLimit: Int? = nil,
        detail: String? = nil,
        detailAccessibilityIdentifier: String? = nil,
        titleLineLimit: Int = 2,
        layout: Layout = .list,
        accessibilityIdentifier: String
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            subtitleMonospaced: subtitleMonospaced,
            subtitleLineLimit: subtitleLineLimit,
            detail: detail,
            detailAccessibilityIdentifier: detailAccessibilityIdentifier,
            titleLineLimit: titleLineLimit,
            layout: layout,
            accessibilityIdentifier: accessibilityIdentifier,
            leading: { EmptyView() },
            trailing: { EmptyView() },
            footer: { EmptyView() }
        )
    }
}

#Preview("CatalogRow") {
    ThemedRoot {
        VStack(spacing: Theme.Space.rowGap) {
            SurfaceCard {
                CatalogRow(
                    title: "build-box",
                    subtitle: "deploy@build.internal",
                    detail: "Last connected 4 minutes ago",
                    accessibilityIdentifier: "preview.row.plain"
                )
            }
            SurfaceCard(isSelected: true) {
                CatalogRow(
                    title: "edge-01",
                    subtitle: "root@10.0.0.7",
                    accessibilityIdentifier: "preview.row.selected"
                ) {
                    RowIconTile(systemImage: "server.rack", label: "Host")
                } trailing: {
                    Image(systemName: "chevron.right").foregroundStyle(Theme.text.tertiary)
                } footer: {
                    EmptyView()
                }
            }
            SurfaceCard {
                CatalogRow(
                    title: "fix: resolve token refresh race",
                    subtitle: "8f3c1d9",
                    subtitleMonospaced: true,
                    detail: "Ada Lovelace",
                    layout: .stacked,
                    accessibilityIdentifier: "preview.row.stacked"
                )
            }
        }
        .padding(Theme.Space.screenMargin)
    }
}
