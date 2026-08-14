import AnySSHUI
import SwiftUI

struct LiveActivityNotificationLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.step2) {
            Image(systemName: StatusToastSeverity.attention.symbolName)
                .font(Theme.Text.caption)
                .foregroundStyle(StatusToastSeverity.attention.color)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.primary)
                .lineLimit(2)
        }
    }
}
