#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct PrivacyPolicyView: View {
    public init() {}

    public var body: some View {
        List {
            ForEach(PrivacyPolicy.sections, id: \.title) { section in
                Section {
                    Text(section.body)
                        .font(Theme.Text.body)
                        .foregroundStyle(Theme.text.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .catalogRowChrome()
                } header: {
                    SectionLabel(section.title)
                }
            }
            Section {
                SectionCaption(
                    "Last updated \(PrivacyPolicy.updated).",
                    tone: Theme.text.tertiary
                )
                .listRowBackground(Color.clear)
            }
        }
        .catalogListSurface()
        .navigationTitle("Privacy")
        .accessibilityIdentifier(UIIdentifier.Settings.privacyScreen)
    }
}

#Preview("PrivacyPolicyView") {
    ThemedRoot {
        NavigationStack {
            PrivacyPolicyView()
        }
    }
}
#endif
