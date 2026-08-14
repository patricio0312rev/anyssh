import SwiftUI

public struct SectionLabel: View {
    private let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(Theme.Text.sectionHeader)
            .foregroundStyle(Theme.text.secondary)
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Theme.Space.step3)
            .padding(.bottom, Theme.Space.step1)
    }
}

#Preview("SectionLabel") {
    ThemedRoot {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Connection")
            SurfaceCard { PrimaryTitle("build-box") }
            SectionLabel("Authentication")
            SurfaceCard { PrimaryTitle("id_ed25519") }
        }
        .padding(Theme.Space.screenMargin)
    }
}
