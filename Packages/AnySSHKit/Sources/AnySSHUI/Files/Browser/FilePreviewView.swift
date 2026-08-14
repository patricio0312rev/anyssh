#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct FilePreviewView: View {
    @State private var model: FilePreviewModel
    @State private var dragOffset: CGFloat = 0
    @State private var wrap = LineWrapPreference.shared

    private let name: String
    private let onClose: () -> Void

    public init(
        path: String,
        name: String,
        browser: any RemoteFileBrowser,
        highlighter: any SyntaxHighlighter,
        onClose: @escaping () -> Void
    ) {
        _model = State(
            wrappedValue: FilePreviewModel(
                path: path, name: name, browser: browser, highlighter: highlighter
            )
        )
        self.name = name
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Theme.surface.base)
        .offset(x: dragOffset)
        .gesture(closeDrag)
        .task { await model.load() }
        .accessibilityIdentifier(UIIdentifier.Workspace.preview)
    }

    private var header: some View {
        HStack(spacing: Theme.Space.step3) {
            IconButton(
                systemImage: "chevron.left",
                label: "Back to files",
                surface: .inline,
                action: onClose
            )
            VStack(alignment: .leading, spacing: Theme.Space.step1) {
                Text(name)
                    .font(Theme.Text.sectionHeader)
                    .foregroundStyle(Theme.text.primary)
                    .lineLimit(1)
                if model.isTruncated {
                    Text("Showing the first part of the file")
                        .font(Theme.Text.caption)
                        .foregroundStyle(Theme.text.tertiary)
                }
            }
            Spacer()
            if case .code = model.rendering { WrapToggle(wrapsLines: $wrap.wrapsLines) }
            if model.hasSource { sourceToggle }
        }
        .padding(.horizontal, Theme.Space.screenMargin)
        .padding(.bottom, Theme.Space.step3)
    }

    private var sourceToggle: some View {
        IconButton(
            systemImage: model.showsSource ? "photo" : "chevron.left.forwardslash.chevron.right",
            label: model.showsSource ? "Show the drawing" : "Show the source",
            surface: .inline,
            accessibilityIdentifier: UIIdentifier.Workspace.previewToggle
        ) {
            withAnimation(FileBrowserMetrics.renderingSwap) { model.showsSource.toggle() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            LoadingView(.screen(label: "Loading file"))
        case .failure(let state):
            ErrorStateView(state: state) { Task { await model.load() } }
        case .loaded:
            rendering
        }
    }

    @ViewBuilder
    private var rendering: some View {
        switch model.rendering {
        case .code(let lines, let tokens):
            CodeTextView(lines: lines, tokens: tokens, wraps: wrap.wrapsLines)
        case .image(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(Theme.Space.screenMargin)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .unreadable(let state):
            ErrorStateView(state: state)
        case .none:
            EmptyView()
        }
    }

    private var closeDrag: some Gesture {
        DragGesture(minimumDistance: FileBrowserMetrics.dragMinimum)
            .onChanged { value in
                guard value.translation.width > 0 else { return }
                dragOffset = value.translation.width
            }
            .onEnded { value in
                if value.translation.width > FileBrowserMetrics.closeThreshold {
                    onClose()
                }
                withAnimation(FileBrowserMetrics.dragSettle) { dragOffset = 0 }
            }
    }
}
#endif
