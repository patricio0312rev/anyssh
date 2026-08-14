#if canImport(UIKit)
import SwiftUI

struct PrivacyCoverView: View {
    var body: some View {
        ZStack {
            Theme.surface.base.ignoresSafeArea()
            Image(systemName: "lock.fill")
                .font(Theme.Text.screenTitle)
                .foregroundStyle(Theme.text.secondary)
        }
        .accessibilityIdentifier(UIIdentifier.Session.privacyCover)
    }
}

#Preview("PrivacyCoverView") {
    ThemedRoot {
        PrivacyCoverView()
    }
}
#endif
