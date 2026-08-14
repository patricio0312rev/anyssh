#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct JSONViewer: View {
    @State private var model: JSONViewerModel
    @Environment(\.statusToasts) private var statusToasts
    private let renderer: any HighlightedTextRendering

    public init(
        ref: BlobRef,
        service: any BlobService,
        highlighter: any SyntaxHighlighter,
        mode: JSONViewerModel.Mode = .text,
        renderer: any HighlightedTextRendering = HighlightedTextRenderer()
    ) {
        _model = State(
            wrappedValue: JSONViewerModel(
                ref: ref, service: service, highlighter: highlighter, mode: mode
            )
        )
        self.renderer = renderer
    }

    public var body: some View {
        content
            .task { await model.load() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { modePicker }
                ToolbarItem(placement: .topBarTrailing) { formatButton }
            }
            .accessibilityIdentifier(UIIdentifier.File.jsonViewer)
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
            ErrorStateView(state: error) { Task { await model.retry() } }
        case .content:
            rendering
        }
    }

    @ViewBuilder
    private var rendering: some View {
        if model.mode == .tree, let tree = model.tree {
            JSONTreeView(model: tree)
        } else {
            HighlightedCodeView(
                attributedText: renderer.attributed(
                    blob: model.displayText,
                    tokens: model.displayTokens
                )
            )
        }
    }

    private var formatButton: some View {
        Button("Format") {
            Task { await model.format() }
        }
        .disabled(!model.canFormat || model.mode == .tree)
        .accessibilityIdentifier(UIIdentifier.File.jsonFormat)
    }

    private var modePicker: some View {
        Picker("Mode", selection: modeBinding) {
            Text("Text").tag(JSONViewerModel.Mode.text)
            Text("Tree").tag(JSONViewerModel.Mode.tree)
        }
        .pickerStyle(.segmented)
        .fixedSize()
        .accessibilityIdentifier(UIIdentifier.File.jsonMode)
    }

    private var modeBinding: Binding<JSONViewerModel.Mode> {
        Binding(
            get: { model.mode },
            set: { mode in
                if mode == .tree, model.tree == nil {
                    statusToasts.present(state: .files(.jsonParseFailed))
                } else {
                    model.select(mode)
                }
            }
        )
    }
}
#endif
