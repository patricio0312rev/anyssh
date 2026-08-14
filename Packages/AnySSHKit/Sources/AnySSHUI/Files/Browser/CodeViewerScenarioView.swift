#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct CodeViewerScenarioView: View {
    @State private var wrap = LineWrapPreference.shared

    public init() {}

    private var lines: [String] {
        (1...40).map { index in
            index % 5 == 0
                ? "    let veryLongIdentifier\(index) = someFunction(argument: \(index), another: \"a string long enough to run past the edge of any phone\")"
                : "    let line\(index) = \(index)"
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Fixture.swift")
                    .font(Theme.Text.sectionHeader)
                    .foregroundStyle(Theme.text.primary)
                Spacer()
                WrapToggle(wrapsLines: $wrap.wrapsLines)
            }
            .padding(.horizontal, Theme.Space.screenMargin)
            .padding(.bottom, Theme.Space.step3)
            CodeTextView(lines: lines, tokens: [], wraps: wrap.wrapsLines)
        }
        .background(Theme.surface.base)
        .accessibilityIdentifier(UIIdentifier.Workspace.preview)
    }
}
#endif
