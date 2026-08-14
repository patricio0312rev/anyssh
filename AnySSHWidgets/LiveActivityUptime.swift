import AnySSHUI
import SwiftUI

struct LiveActivityUptime: View {
    let seconds: TimeInterval
    var showsLabel = false

    var body: some View {
        VStack(alignment: .trailing, spacing: Theme.Space.step1) {
            Text(LiveActivityStatus.uptime(seconds))
                .font(Theme.Text.caption)
                .monospacedDigit()
                .foregroundStyle(Theme.text.secondary)
            if showsLabel {
                Text("UPTIME")
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.tertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Uptime")
        .accessibilityValue(LiveActivityStatus.uptime(seconds))
    }
}
