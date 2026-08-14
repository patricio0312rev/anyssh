import ImageIO
import MarkdownView
import SwiftUI

@MainActor
public struct SSHMarkdownImageRenderer: MarkdownImageRenderer {
    public typealias Configuration = MarkdownImageRendererConfiguration

    public static let maxPixelSize = 2048

    let loader: any MarkdownImageLoader

    public init(loader: any MarkdownImageLoader) {
        self.loader = loader
    }

    @ViewBuilder
    public func makeBody(configuration: Configuration) -> some View {
        SSHMarkdownImageView(
            url: configuration.url,
            alternativeText: configuration.alternativeText,
            loader: loader
        )
    }
}

struct SSHMarkdownImageView: View {
    let url: URL
    let alternativeText: String?
    let loader: any MarkdownImageLoader

    @State private var phase: Phase = .loading

    var body: some View {
        Group {
            switch phase {
            case .loading:
                LoadingView(.inline)
            case .loaded(let image):
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
            case .failed:
                Text(alternativeText ?? "Image")
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .task(id: url) { await load() }
    }

    private func load() async {
        phase = .loading
        do {
            let data = try await loader.loadImage(repositoryPath: repositoryPath)
            let maxPixelSize = SSHMarkdownImageRenderer.maxPixelSize
            let image = ImageThumbnailDecoder().decode(data, maxPixelSize: maxPixelSize)
            phase = image.map(Phase.loaded) ?? .failed
        } catch {
            phase = .failed
        }
    }

    private var repositoryPath: String {
        let path = url.path
        return path.hasPrefix("/") ? String(path.dropFirst()) : path
    }

    private enum Phase {
        case loading
        case loaded(CGImage)
        case failed
    }
}
