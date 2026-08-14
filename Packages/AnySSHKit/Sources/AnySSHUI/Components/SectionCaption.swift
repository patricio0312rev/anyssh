import SwiftUI

public struct SectionCaption: View {
    private let text: String
    private let tone: Color

    public init(_ text: String, tone: Color = Theme.text.secondary) {
        self.text = text
        self.tone = tone
    }

    public var body: some View {
        Text(text)
            .font(Theme.Text.caption)
            .foregroundStyle(tone)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
    }
}

#Preview("SectionCaption") {
    ThemedRoot {
        List {
            Section {
                PrimaryTitle("build-box")
                    .catalogRowChrome()
            } header: {
                SectionLabel("Connection")
            } footer: {
                SectionCaption("The host is reached over SSH and nothing is installed on it.")
            }
        }
        .catalogListSurface()
    }
}
