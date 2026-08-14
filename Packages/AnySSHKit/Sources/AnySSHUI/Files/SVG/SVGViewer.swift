#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct SVGViewer: View {
    @State private var model: SVGViewerModel

    public init(ref: BlobRef, service: any BlobService) {
        _model = State(wrappedValue: SVGViewerModel(ref: ref, service: service))
    }

    public var body: some View {
        content
            .task { await model.load() }
            .accessibilityIdentifier(UIIdentifier.File.svgViewer)
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            LoadingView(.screen(label: "Loading drawing"))
        case .refusal(let error), .fallback(let error):
            VStack(spacing: 0) {
                ErrorStateView(state: error)
                source
            }
        case .content:
            drawing
        case .failed(let error):
            ErrorStateView(state: error) { Task { await model.load() } }
        }
    }

    private var source: some View {
        ScrollView([.vertical, .horizontal]) {
            Text(model.source)
                .font(Theme.code())
                .foregroundStyle(Theme.Code.foreground)
                .textSelection(.enabled)
                .padding(.horizontal, Theme.Space.screenMargin)
                .padding(.vertical, Theme.Space.step3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.Code.canvas)
        .accessibilityIdentifier(UIIdentifier.File.codeContent)
    }

    @ViewBuilder
    private var drawing: some View {
        if let image = model.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(Theme.Space.screenMargin)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.surface.base)
        }
    }
}
#endif
