import SwiftUI

public struct IconButton: View {
    public enum Surface {
        case toolbar
        case inline
        case raised
    }

    private let systemImage: String
    private let label: String
    private let surface: Surface
    private let accessibilityIdentifier: String?
    private let action: () -> Void

    public init(
        systemImage: String,
        label: String,
        surface: Surface,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.label = label
        self.surface = surface
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(Theme.Text.body)
                .modifier(HitTarget(surface: surface))
        }
        .modifier(SurfaceStyle(surface: surface))
        .accessibilityLabel(label)
        .accessibilityIdentifier(accessibilityIdentifier ?? "")
    }

    private struct HitTarget: ViewModifier {
        let surface: Surface

        func body(content: Content) -> some View {
            switch surface {
            case .toolbar:
                content
            case .inline, .raised:
                content
                    .frame(
                        width: Theme.Buttons.iconHitTarget,
                        height: Theme.Buttons.iconHitTarget
                    )
                    .contentShape(.rect)
            }
        }
    }

    private struct SurfaceStyle: ViewModifier {
        let surface: Surface

        func body(content: Content) -> some View {
            switch surface {
            case .toolbar: content
            case .inline: content.buttonStyle(.glass).buttonBorderShape(.circle)
            case .raised: content.buttonStyle(.plain).background(Theme.surface.raised, in: Circle())
            }
        }
    }
}

#Preview("IconButton") {
    ThemedRoot {
        HStack(spacing: Theme.Space.step4) {
            IconButton(systemImage: "gearshape", label: "Settings", surface: .inline) {}
            IconButton(systemImage: "gearshape", label: "Settings", surface: .raised) {}
            IconButton(systemImage: "plus", label: "Add host", surface: .toolbar) {}
        }
    }
}
