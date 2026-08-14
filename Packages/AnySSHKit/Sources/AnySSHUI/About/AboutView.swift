#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct AboutView: View {
    private let version: String
    private let build: String

    public init(version: String, build: String) {
        self.version = version
        self.build = build
    }

    public var body: some View {
        List {
            privacy
            links
            notices
        }
        .catalogListSurface()
        .navigationTitle("About")
        .accessibilityIdentifier(UIIdentifier.About.screen)
    }

    private var privacy: some View {
        Section {
            Text("Nothing you type, and nothing a host sends back, leaves this device.")
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .catalogRowChrome()
        } header: {
            SectionLabel("Privacy")
        } footer: {
            SectionCaption(
                "Keys live in the iOS Keychain, guarded by Face ID. There is no account, no "
                    + "server of ours, and nothing is installed on the hosts you connect to."
            )
        }
    }

    private var links: some View {
        Section {
            ForEach(ProjectLinks.all) { link in
                if let destination = URL(string: link.url) {
                    Link(destination: destination) {
                        CatalogRow(
                            title: link.title,
                            subtitle: link.subtitle,
                            accessibilityIdentifier: UIIdentifier.About.link(link.title),
                            leading: { RowIconTile(systemImage: link.icon, label: link.title) },
                            trailing: { LinkArrow() },
                            footer: { EmptyView() }
                        )
                    }
                    .catalogRowChrome()
                }
            }
        } header: {
            SectionLabel("Links")
        }
    }

    private var notices: some View {
        Section {
            ForEach(ThirdPartyNotices.all.sorted()) { notice in
                NavigationLink {
                    NoticeDetailView(notice: notice)
                } label: {
                    NoticeRow(notice: notice)
                }
                .catalogRowChrome()
            }
        } header: {
            SectionLabel("Built with")
        } footer: {
            VStack(alignment: .leading, spacing: Theme.Space.step1) {
                SectionCaption("Each notice is the licence text as its project publishes it.")
                Text("AnySSH \(version) (\(build))")
                    .font(Theme.code())
                    .foregroundStyle(Theme.text.tertiary)
                    .accessibilityIdentifier(UIIdentifier.About.version)
            }
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
        }
    }
}

private struct LinkArrow: View {
    var body: some View {
        Image(systemName: "arrow.up.forward")
            .font(Theme.Text.caption)
            .foregroundStyle(Theme.text.tertiary)
    }
}

#Preview("AboutView") {
    ThemedRoot {
        NavigationStack {
            AboutView(version: "1.4", build: "212")
        }
    }
}
#endif
