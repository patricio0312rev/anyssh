#if canImport(UIKit)
import AVKit
import AnySSHCore
import SwiftUI

public struct VideoViewer: View {
    @State private var model: VideoViewerModel

    public init(ref: BlobRef, service: any BlobService) {
        _model = State(wrappedValue: VideoViewerModel(ref: ref, service: service))
    }

    public var body: some View {
        content
            .task { await model.load() }
            .onDisappear { model.dismiss() }
            .accessibilityIdentifier(UIIdentifier.File.videoViewer)
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            LoadingView(.screen(label: "Loading video"))
        case .confirmation(let byteCount):
            confirmation(byteCount)
        case .playing:
            player
        case .refusal(let error), .failed(let error):
            ErrorStateView(state: error) { Task { await model.load() } }
        }
    }

    private func confirmation(_ byteCount: Int) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.step5) {
            VStack(alignment: .leading, spacing: Theme.Space.step2) {
                Text("Download video to play")
                    .font(Theme.Text.screenTitle)
                    .foregroundStyle(Theme.text.primary)
                Text("This file is \(byteCount.formatted(.byteCount(style: .file))).")
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
            }
            Button {
                Task { await model.confirmDownload() }
            } label: {
                Text("Download")
                    .font(Theme.Text.body)
                    .frame(maxWidth: .infinity, minHeight: Theme.Buttons.height)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.accent)
            .accessibilityIdentifier(UIIdentifier.File.videoDownload)
        }
        .padding(Theme.Space.step5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.surface.base)
    }

    @ViewBuilder
    private var player: some View {
        if let player = model.player {
            VideoPlayer(player: player).background(Theme.surface.base)
        }
    }
}
#endif
