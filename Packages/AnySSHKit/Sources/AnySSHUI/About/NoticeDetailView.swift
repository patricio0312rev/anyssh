#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct NoticeDetailView: View {
    private let notice: ThirdPartyNotice

    @Environment(\.noticeTextProvider) private var provider

    public init(notice: ThirdPartyNotice) {
        self.notice = notice
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.step3) {
                Text(notice.url)
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.tertiary)
                    .textSelection(.enabled)
                Text(provider.text(of: notice) ?? Self.missing)
                    .font(Theme.code())
                    .foregroundStyle(Theme.text.secondary)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Space.screenMargin)
        }
        .background { Theme.surface.base.ignoresSafeArea() }
        .navigationTitle(notice.name)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(UIIdentifier.About.noticeText)
    }

    private static let missing = "This notice did not ship with the app."
}

#Preview("NoticeDetailView") {
    ThemedRoot {
        NavigationStack {
            NoticeDetailView(notice: ThirdPartyNotices.all[0])
        }
    }
}
#endif
