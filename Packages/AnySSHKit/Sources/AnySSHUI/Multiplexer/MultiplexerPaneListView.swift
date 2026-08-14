import AnySSHCore
import SwiftUI

public struct MultiplexerPaneListView: View {
    @State private var model: MultiplexerPaneListModel
    @Environment(\.statusToasts) private var statusToasts
    private let writer: (any DisplayWriter)?
    private let onDismiss: (() -> Void)?

    public init(
        adapter: any MultiplexerAdapter,
        writer: (any DisplayWriter)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        _model = State(wrappedValue: MultiplexerPaneListModel(adapter: adapter))
        self.writer = writer
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background { Theme.surface.base.ignoresSafeArea() }
        .task { await model.load() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(MultiplexerIdentifier.paneList)
    }

    private var header: some View {
        ScreenHeader("Panes") {
            if let onDismiss {
                CloseButton(
                    accessibilityIdentifier: MultiplexerIdentifier.paneListClose,
                    action: onDismiss
                )
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            LoadingView(.screen(label: "Loading panes"))
        } else if let failureState = model.failureState {
            ErrorStateView(state: failureState) {
                Task { await model.load() }
            }
        } else {
            List {
                ForEach(model.sessions) { session in
                    sessionSection(session)
                }
            }
            .catalogListSurface()
        }
    }

    private func sessionSection(_ session: MuxSession) -> some View {
        Section {
            ForEach(model.snapshot(for: session.id)?.panes ?? []) { pane in
                Button {
                    attach(session.id)
                } label: {
                    CatalogRow(
                        title: pane.title,
                        subtitle: pane.workingDirectory,
                        subtitleMonospaced: true,
                        detail: pane.agentStatus,
                        accessibilityIdentifier: MultiplexerIdentifier.pane(pane.id.rawValue)
                    )
                }
                .buttonStyle(.plain)
                .catalogRowChrome(selected: pane.isActive)
            }
        } header: {
            SectionLabel(session.name)
        }
    }

    private func attach(_ session: MuxSessionID) {
        let command = model.attachCommand(for: session)
        guard !command.isEmpty, let writer else { return }
        Task {
            do {
                try await writer.send(Array((command + "\r").utf8)[...])
            } catch {
                statusToasts.present(state: .mux(.attachTargetVanished))
            }
        }
    }
}
