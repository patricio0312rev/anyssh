import SwiftUI

struct SessionPolicyFooter: View {
    var body: some View {
        Text(
            "Backgrounding ends this session. Work continues on the host only if it is inside tmux or herdr."
        )
        .font(Theme.Text.caption)
        .foregroundStyle(Theme.text.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.Space.screenMargin)
        .padding(.bottom, Theme.Space.screenMargin)
    }
}
