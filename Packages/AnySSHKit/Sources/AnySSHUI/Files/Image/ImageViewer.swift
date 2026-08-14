#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct ImageViewer: View {
    @State private var model: ImageViewerModel

    public init(
        ref: BlobRef,
        service: any BlobService,
        maxPixelSize: Int = ImageViewerModel.defaultMaxPixelSize
    ) {
        _model = State(
            wrappedValue: ImageViewerModel(ref: ref, service: service, maxPixelSize: maxPixelSize)
        )
    }

    public var body: some View {
        content
            .task { await model.load() }
            .background(Theme.surface.base)
            .accessibilityIdentifier(UIIdentifier.File.imageViewer)
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            LoadingView(.screen(label: "Loading image"))
        case .failed(let error):
            ErrorStateView(state: error) { Task { await model.load() } }
        case .loaded(let image):
            Image(uiImage: UIImage(cgImage: image))
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .padding(Theme.Space.screenMargin)
        }
    }
}
#endif
