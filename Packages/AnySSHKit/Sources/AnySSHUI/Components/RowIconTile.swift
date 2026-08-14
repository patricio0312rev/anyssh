import SwiftUI

public struct RowIconTile: View {
    private enum Mark {
        case symbol(String)
        case monogram(String)
    }

    @ScaledMetric(relativeTo: .headline) private var tile = Theme.Space.iconTile
    @ScaledMetric(relativeTo: .headline) private var glyph = Theme.Space.iconGlyph
    @ScaledMetric(relativeTo: .headline) private var radius = Theme.Space.controlRadius

    private let mark: Mark
    private let tint: Color
    private let label: String

    public init(systemImage: String, label: String, tint: Color = Theme.text.primary) {
        mark = .symbol(systemImage)
        self.tint = tint
        self.label = label
    }

    public init(monogram: String, label: String, tint: Color = Theme.text.primary) {
        mark = .monogram(monogram)
        self.tint = tint
        self.label = label
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Theme.surface.overlay)
            .frame(width: tile, height: tile)
            .overlay { content }
            .accessibilityLabel(label)
    }

    @ViewBuilder
    private var content: some View {
        switch mark {
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
}

#Preview("RowIconTile") {
    ThemedRoot {
        HStack(spacing: Theme.Space.step3) {
            RowIconTile(systemImage: "server.rack", label: "Host")
            RowIconTile(systemImage: "folder", label: "Folder")
            RowIconTile(monogram: "A", label: "Agent")
            RowIconTile(monogram: "tm", label: "tmux")
        }
        .padding(Theme.Space.screenMargin)
    }
}
