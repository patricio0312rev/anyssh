import SwiftUI

struct LiveActivityAppMark: View {
    let size: CGFloat

    var body: some View {
        Image("AppMark")
            .resizable()
            .frame(width: size, height: size)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: size * LiveActivityMetrics.markRadiusScale,
                    style: .continuous
                )
            )
            .accessibilityHidden(true)
    }
}
