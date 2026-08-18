#if canImport(UIKit)
import AnySSHCore
import SwiftUI

struct SessionNavbarChrome: View {
    let title: String
    let transportState: TransportState

    var body: some View {
        VStack(spacing: Theme.Space.step1) {
            Text(title)
                .font(Theme.Text.sectionHeader)
                .foregroundStyle(Theme.text.primary)
                .lineLimit(1)
                .truncationMode(.middle)
            SessionConnectionStatusLabel(state: transportState)
        }
    }
}
#endif
