#if canImport(UIKit)
import CoreGraphics
import SwiftUI
import UIKit

public struct ImageComparisonView: View {
    private let before: CGImage
    private let after: CGImage
    private let layout: ImageComparisonLayout
    @State private var mode: ImageComparisonMode
    @State private var fraction: CGFloat

    private static let dividerWidth: CGFloat = 2

    public init(
        before: CGImage,
        after: CGImage,
        mode: ImageComparisonMode = .twoUp,
        fraction: CGFloat = 0.5
    ) {
        self.before = before
        self.after = after
        layout = ImageComparisonLayoutBuilder.layout(before: before, after: after)
        _mode = State(initialValue: mode)
        _fraction = State(initialValue: min(max(fraction, 0), 1))
    }

    public var body: some View {
        VStack(spacing: Theme.Space.step3) {
            Picker("Comparison", selection: $mode) {
                Text("2-up").tag(ImageComparisonMode.twoUp)
                Text("Swipe").tag(ImageComparisonMode.swipe)
                Text("Onion skin").tag(ImageComparisonMode.onionSkin)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(UIIdentifier.File.imageMode)
            comparison
            Text(layout.dimensionDeltaLabel)
                .font(Theme.code())
                .foregroundStyle(Theme.text.secondary)
                .accessibilityIdentifier(UIIdentifier.File.imageDimensions)
            if mode != .twoUp {
                Slider(value: $fraction)
                    .accessibilityIdentifier(UIIdentifier.File.imageFraction)
            }
        }
        .padding(Theme.Space.screenMargin)
        .background(Theme.surface.base)
        .accessibilityIdentifier(UIIdentifier.File.imageComparison)
    }

    @ViewBuilder
    private var comparison: some View {
        switch mode {
        case .twoUp:
            HStack(spacing: Theme.Space.step3) {
                letterboxed(before)
                letterboxed(after)
            }
        case .swipe:
            swipe
        case .onionSkin:
            onionSkin
        }
    }

    private var swipe: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                letterboxed(before)
                letterboxed(after)
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: width * fraction)
                    }
                Rectangle()
                    .fill(Theme.text.primary)
                    .frame(width: Self.dividerWidth)
                    .offset(x: width * fraction - Self.dividerWidth / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { value in
                    fraction = min(max(value.location.x / max(width, 1), 0), 1)
                }
            )
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(unionAspectRatio, contentMode: .fit)
    }

    private var onionSkin: some View {
        ZStack {
            letterboxed(before)
            letterboxed(after).opacity(fraction)
        }
        .compositingGroup()
        .aspectRatio(unionAspectRatio, contentMode: .fit)
    }

    private var unionAspectRatio: CGFloat {
        CGFloat(layout.union.width) / CGFloat(layout.union.height)
    }

    private func letterboxed(_ image: CGImage) -> some View {
        Color.clear
            .aspectRatio(unionAspectRatio, contentMode: .fit)
            .overlay(alignment: .topLeading) {
                GeometryReader { proxy in
                    let scale = proxy.size.width / CGFloat(layout.union.width)
                    Image(uiImage: UIImage(cgImage: image))
                        .resizable()
                        .interpolation(.high)
                        .frame(
                            width: CGFloat(image.width) * scale,
                            height: CGFloat(image.height) * scale,
                            alignment: .topLeading
                        )
                }
            }
            .clipped()
    }
}
#endif
