#if canImport(UIKit)
import SwiftUI

struct WorkspacePathHeader: View {
    let components: [String]
    let isAtRoot: Bool
    let onUp: () -> Void

    var body: some View {
        HStack(spacing: Theme.Space.step3) {
            if !isAtRoot {
                IconButton(
                    systemImage: "chevron.left",
                    label: "Up one directory",
                    surface: .inline,
                    action: onUp
                )
            }
            trail
        }
        .padding(.horizontal, Theme.Space.screenMargin)
        .padding(.bottom, Theme.Space.step3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UIIdentifier.Workspace.breadcrumb)
    }

    private var trail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Space.step1) {
                ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                    if index > 0 {
                        Text("/").foregroundStyle(Theme.text.tertiary)
                    }
                    Text(component)
                        .foregroundStyle(
                            index == components.count - 1
                                ? Theme.text.primary : Theme.text.secondary
                        )
                }
            }
            .font(Theme.code())
            .padding(.vertical, Theme.Space.step1)
        }
        .defaultScrollAnchor(.trailing)
    }
}

#Preview("WorkspacePathHeader") {
    ThemedRoot {
        VStack(spacing: Theme.Space.step5) {
            WorkspacePathHeader(components: ["anyssh"], isAtRoot: true) {}
            WorkspacePathHeader(
                components: ["anyssh", "Packages", "AnySSHKit", "Sources"],
                isAtRoot: false
            ) {}
        }
    }
}
#endif
