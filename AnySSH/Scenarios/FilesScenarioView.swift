import AnySSHCore
import AnySSHMocks
import AnySSHUI
import Foundation
import SwiftUI

struct FilesScenarioView: View {
    let scenario: FilesScenario

    @Environment(\.syntaxHighlighter) private var highlighter

    var body: some View {
        NavigationStack {
            surface
        }
        .tint(Theme.accent)
    }

    @ViewBuilder
    private var surface: some View {
        switch scenario {
        case .browser:
            FileBrowserView(root: FileFixtures.root, browser: MockRemoteFileBrowser(.populated))
        case .browserTruncated:
            FileBrowserView(root: FileFixtures.root, browser: MockRemoteFileBrowser(.truncated))
        case .browserUnreachable:
            FileBrowserView(root: FileFixtures.root, browser: MockRemoteFileBrowser(.unreachable))
        case .preview:
            preview(path: FileFixtures.root + "/Package.swift", name: "Package.swift")
        case .previewImage:
            preview(path: FileFixtures.root + "/screenshot.png", name: "screenshot.png")
        case .previewVector:
            preview(path: FileFixtures.root + "/icon.svg", name: "icon.svg")
        case .viewer:
            CodeViewerScenarioView()
        case .source:
            source(MockBlobService(.available))
        case .sourceRefusal:
            source(MockBlobService(.overCap))
        case .json:
            json(mode: .text)
        case .jsonTree:
            json(mode: .tree)
        case .jsonTreeExpanded:
            expandedTree
        case .markdown:
            MarkdownDocumentView(
                configuration: MarkdownViewConfiguration(
                    source: FileFixtures.markdownSource,
                    filePath: "README.md",
                    loader: FixtureMarkdownImageLoader(),
                    highlighter: highlighter
                )
            )
        case .image:
            ImageViewer(ref: FileFixtures.blob("before.png"), service: MockBlobService())
        case .imageComparison:
            comparison
        case .svg:
            SVGViewer(ref: FileFixtures.blob("icon.svg"), service: MockBlobService())
        case .video:
            VideoViewer(
                ref: FileFixtures.blob("capture.mp4"),
                service: MockBlobService(byteCount: 30 * 1024 * 1024)
            )
        case .videoUnsupported:
            VideoViewer(ref: FileFixtures.blob("capture.mkv"), service: MockBlobService())
        }
    }

    private func preview(path: String, name: String) -> some View {
        FilePreviewView(
            path: path,
            name: name,
            browser: MockRemoteFileBrowser(.populated),
            highlighter: highlighter,
            onClose: {}
        )
    }

    private func source(_ service: MockBlobService) -> some View {
        SourceViewer(
            ref: FileFixtures.blob("Package.swift"),
            service: service,
            highlighter: highlighter,
            language: .swift
        )
    }

    private func json(mode: JSONViewerModel.Mode) -> some View {
        JSONViewer(
            ref: FileFixtures.blob("config.json"),
            service: MockBlobService(),
            highlighter: highlighter,
            mode: mode
        )
        .navigationTitle("config.json")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var expandedTree: some View {
        if let root = try? JSONTextParser.parse(FileFixtures.jsonSource) {
            JSONTreeView(model: FilesScenarioView.expanded(JSONTreeModel(root: root)))
                .navigationTitle("config.json")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private static func expanded(_ model: JSONTreeModel) -> JSONTreeModel {
        var model = model
        guard let root = model.rows.first else { return model }
        model.expand(root.id)
        for index in (1..<model.visibleRowCount).reversed() where model.row(at: index).isExpandable {
            model.expand(model.row(at: index).id)
        }
        return model
    }

    @ViewBuilder
    private var comparison: some View {
        if let before = ImageFixtures.image(from: ImageFixtures.before),
            let after = ImageFixtures.image(from: ImageFixtures.after)
        {
            ImageComparisonView(before: before, after: after)
        }
    }
}

private struct FixtureMarkdownImageLoader: MarkdownImageLoader {
    func loadImage(repositoryPath: String) async throws -> Data {
        ImageFixtures.before
    }
}
