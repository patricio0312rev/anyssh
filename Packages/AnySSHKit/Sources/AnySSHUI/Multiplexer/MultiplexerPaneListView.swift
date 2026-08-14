import AnySSHCore
import SwiftUI

public struct MultiplexerPaneListView: View {
    @State private var model: MultiplexerPaneListModel
    @Environment(\.statusToasts) private var statusToasts
    private let onDismiss: (() -> Void)?

    public init(
        adapter: any MultiplexerAdapter,
        writer: (any DisplayWriter)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        _model = State(wrappedValue: MultiplexerPaneListModel(adapter: adapter, writer: writer))
        self.onDismiss = onDismiss
    }

    public var body: some View {
        SheetScaffold(
            "Panes",
            closeIdentifier: MultiplexerIdentifier.paneListClose,
            onClose: onDismiss
        ) {
            VStack(spacing: 0) { content }
        }
        .task { await model.load() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(MultiplexerIdentifier.paneList)
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
            failure
            List {
                ForEach(model.sessions) { session in
                    sessionSection(session)
                }
            }
            .catalogListSurface()
        }
    }

    @ViewBuilder
    private var failure: some View {
        if let state = model.attachFailure {
            SectionCaption(state.copy.title, tone: Theme.status.attention)
                .padding(.horizontal, Theme.Space.screenMargin)
                .padding(.bottom, Theme.Space.step2)
                .accessibilityIdentifier(MultiplexerIdentifier.paneListFailure)
        }
    }

    private func sessionSection(_ session: MuxSession) -> some View {
        Section {
            ForEach(model.snapshot(for: session.id)?.panes ?? []) { pane in
                Button {
                    attach(session, from: pane.id)
                } label: {
                    CatalogRow(
                        title: pane.title,
                        subtitle: pane.workingDirectory,
                        subtitleMonospaced: true,
                        detail: pane.agentStatus,
                        accessibilityIdentifier: MultiplexerIdentifier.pane(pane.id.rawValue),
                        leading: { EmptyView() },
                        trailing: { attaching(pane.id) },
                        footer: { EmptyView() }
                    )
                }
                .buttonStyle(.plain)
                .catalogRowChrome(selected: pane.isActive)
            }
        } header: {
            SectionLabel(session.name)
        }
    }

    @ViewBuilder
    private func attaching(_ pane: MuxPaneID) -> some View {
        if model.attachingPaneID == pane {
            LoadingView(.inline)
                .accessibilityIdentifier(MultiplexerIdentifier.attaching(pane.rawValue))
        }
    }

    private func attach(_ session: MuxSession, from pane: MuxPaneID) {
        guard !model.isAttaching else { return }
        Task {
            guard await model.attach(to: session.id, from: pane) else { return }
            onDismiss?()
            statusToasts.present(severity: .success, title: "Attached to \(session.name)")
        }
    }
}
