#if canImport(UIKit)
import AnySSHCore
import SwiftUI

struct NoticeRow: View {
    let notice: ThirdPartyNotice

    var body: some View {
        CatalogRow(
            title: notice.name,
            subtitle: notice.licence,
            titleLineLimit: 1,
            accessibilityIdentifier: UIIdentifier.About.notice(notice.resource)
        )
    }
}

#Preview("NoticeRow") {
    ThemedRoot {
        List {
            ForEach(ThirdPartyNotices.all.sorted().prefix(3)) { notice in
                NoticeRow(notice: notice)
                    .catalogRowChrome()
            }
        }
        .catalogListSurface()
    }
}
#endif
