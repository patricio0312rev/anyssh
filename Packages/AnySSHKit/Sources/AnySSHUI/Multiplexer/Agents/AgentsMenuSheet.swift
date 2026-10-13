import AnySSHCore
import SwiftUI

public struct AgentsMenuSheet: View {
    @State private var model: JumpToModel
    @Environment(\.statusToasts) private var statusToasts
    private let onDismiss: () -> Void

    public init(model: JumpToModel, onDismiss: @escaping () -> Void) {
        _model = State(wrappedValue: model)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        SheetScaffold(AgentsMenuCopy.title, closeIdentifier: AgentsMenuIdentifier.close, onClose: onDismiss) {
            VStack(spacing: 0) {
                failure
                content
            }
        }
        .task { await model.load() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AgentsMenuIdentifier.sheet)
    }

    @ViewBuilder
    private var failure: some View {
        if let state = model.jumpFailure {
            SectionCaption(state.copy.title, tone: Theme.status.attention)
                .padding(.horizontal, Theme.Space.screenMargin)
                .padding(.bottom, Theme.Space.step2)
                .accessibilityIdentifier(AgentsMenuIdentifier.failure)
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            LoadingView(.screen(label: AgentsMenuCopy.loading))
        } else if model.loadFailed {
            ErrorStateView(state: model.failureState ?? .mux(.attachTargetVanished)) {
                Task { await model.load() }
            }
        } else if model.agentSessions.isEmpty {
            Text(AgentsMenuCopy.empty)
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier(AgentsMenuIdentifier.empty)
        } else {
            list
        }
    }

    private var list: some View {
        List {
            ForEach(model.agentSessions) { session in
                Section {
                    ForEach(session.agents) { entry in
                        AgentsMenuRow(
                            entry: entry,
                            isJumping: model.jumpingAgentID == entry.id,
                            onTap: { jump(entry) }
                        )
                        .catalogRowChrome(selected: entry.isActive)
                    }
                } header: {
                    if model.agentSessions.count > 1 {
                        SectionLabel(session.name)
                            .accessibilityIdentifier(AgentsMenuIdentifier.session(session.id.rawValue))
                    }
                }
            }
        }
        .catalogListSurface()
    }

    private func jump(_ entry: MuxAgentEntry) {
        guard !model.isJumping else { return }
        Task {
            guard await model.jump(to: entry) else { return }
            onDismiss()
            MuxJumpAnnouncement.present(on: statusToasts, target: entry.title, model: model)
        }
    }
}
