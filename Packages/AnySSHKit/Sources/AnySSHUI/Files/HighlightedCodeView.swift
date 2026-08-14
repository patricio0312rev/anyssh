import AnySSHCore
import SwiftUI

public struct HighlightedCodeView: View {
    public let attributedText: AttributedString

    public init(attributedText: AttributedString) {
        self.attributedText = attributedText
    }

    public var body: some View {
        ScrollView(.vertical) {
            ScrollView(.horizontal) {
                Text(attributedText)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, Theme.Space.screenMargin)
                    .padding(.vertical, Theme.Space.step3)
            }
        }
        .background(Theme.Code.canvas)
        .accessibilityIdentifier(UIIdentifier.File.codeContent)
    }
}
