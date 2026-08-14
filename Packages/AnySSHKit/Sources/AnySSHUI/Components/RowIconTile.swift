import SwiftUI

public struct RowIconTile: View {
    private enum Mark {
        case symbol(String)
        case monogram(String)
        case asset(String)
    }

    @ScaledMetric(relativeTo: .headline) private var tile = Theme.Space.iconTile
    @ScaledMetric(relativeTo: .headline) private var glyph = Theme.Space.iconGlyph
    @ScaledMetric(relativeTo: .headline) private var radius = Theme.Space.controlRadius

    private let mark: Mark
    private let tint: Color
    private let label: String
    private let fillsTile: Bool

    public init(systemImage: String, label: String, tint: Color = Theme.text.primary) {
        mark = .symbol(systemImage)
        self.tint = tint
        self.label = label
        fillsTile = false
    }

    public init(monogram: String, label: String, tint: Color = Theme.text.primary) {
        mark = .monogram(monogram)
        self.tint = tint
        self.label = label
        fillsTile = false
    }

    public init(
        asset: String,
        label: String,
        tint: Color = Theme.text.primary,
        fillsTile: Bool = false
    ) {
        mark = .asset(asset)
        self.tint = tint
        self.label = label
        self.fillsTile = fillsTile
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Theme.surface.overlay)
            .frame(width: tile, height: tile)
            .overlay { content }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .accessibilityLabel(label)
    }

    @ViewBuilder
    private var content: some View {
        switch mark {
        case .asset(let name):
            assetMark(name)
        case .symbol(let name):
            Image(systemName: name)
                .resizable()
                .scaledToFit()
                .frame(width: glyph, height: glyph)
                .foregroundStyle(tint)
        case .monogram(let text):
            Text(text)
                .font(Theme.Text.body)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: glyph, height: glyph)
        }
    }

    @ViewBuilder
    private func assetMark(_ name: String) -> some View {
        let mark = Image(name, bundle: .main)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(tint)
        if fillsTile {
            mark
                .frame(width: tile, height: tile)
                .frame(width: tile, height: tile, alignment: .bottomTrailing)
        } else {
            mark.frame(width: glyph, height: glyph)
        }
    }
}

#Preview("RowIconTile") {
    ThemedRoot {
        HStack(spacing: Theme.Space.step3) {
            RowIconTile(systemImage: "server.rack", label: "Host")
            RowIconTile(systemImage: "folder", label: "Folder")
            RowIconTile(monogram: "A", label: "Agent")
            RowIconTile(monogram: "tm", label: "tmux")
            RowIconTile(asset: "AgentMarks/codex", label: "Codex")
        }
        .padding(Theme.Space.screenMargin)
    }
}
