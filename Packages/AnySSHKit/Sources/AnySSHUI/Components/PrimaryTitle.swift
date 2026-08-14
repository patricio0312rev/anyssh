import SwiftUI

public struct PrimaryTitle: View {
    private let text: String
    private let lineLimit: Int
    private let truncationMode: Text.TruncationMode

    public init(
        _ text: String,
        lineLimit: Int = 1,
        truncationMode: Text.TruncationMode = .tail
    ) {
        self.text = text
        self.lineLimit = lineLimit
        self.truncationMode = truncationMode
    }

    public var body: some View {
        Text(text)
            .font(Theme.Text.body)
            .foregroundStyle(Theme.text.primary)
            .lineLimit(lineLimit)
            .truncationMode(truncationMode)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("PrimaryTitle") {
    ThemedRoot {
        VStack(alignment: .leading, spacing: Theme.Space.step2) {
            PrimaryTitle("build-box")
            PrimaryTitle("a name long enough to need truncation on a narrow screen")
            PrimaryTitle("wrapped over two lines when the caller allows it", lineLimit: 2)
        }
        .padding(Theme.Space.screenMargin)
    }
}
