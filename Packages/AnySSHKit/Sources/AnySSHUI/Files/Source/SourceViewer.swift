import AnySSHCore
import SwiftUI

public struct SourceViewer: View {
    @State private var model: SourceViewerModel
    private let renderer: any HighlightedTextRendering

    public init(
        ref: BlobRef,
        service: any BlobService,
        highlighter: any SyntaxHighlighter,
        language: LanguageID,
        cap: Int = SourceViewerModel.cap,
        renderer: any HighlightedTextRendering = HighlightedTextRenderer()
    ) {
        _model = State(
            wrappedValue: SourceViewerModel(
                ref: ref,
                service: service,
                highlighter: highlighter,
                language: language,
                cap: cap
            )
        )
        self.renderer = renderer
    }

    public var body: some View {
        content
            .task { await model.load() }
            .accessibilityIdentifier(UIIdentifier.File.sourceViewer)
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            LoadingView(.screen(label: "Loading file"))
                .background(Theme.Code.canvas)
        case .refusal(let error):
            ErrorStateView(state: error) { Task { await model.openAnyway() } }
        case .failed(let error):
            ErrorStateView(state: error) { Task { await model.load() } }
        case .content(let document):
            HighlightedCodeView(
                attributedText: renderer.attributed(blob: document.text, tokens: document.tokens)
            )
        }
    }
}
