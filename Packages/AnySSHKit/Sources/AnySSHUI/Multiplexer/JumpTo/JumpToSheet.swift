import AnySSHCore
import SwiftUI

public struct JumpToSheet: View {
    @State private var model: JumpToModel
    @Environment(\.statusToasts) private var statusToasts
    private let onDismiss: () -> Void

    public init(model: JumpToModel, onDismiss: @escaping () -> Void) {
        _model = State(wrappedValue: model)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        SheetScaffold("Jump to", closeIdentifier: JumpToIdentifier.close, onClose: onDismiss) {
            VStack(spacing: 0) {
                layoutSwitcher
                if model.kind == .tmux {
                    explanation
                }
                failure
                content
                bytesProbe
            }
        }
        .task { await model.load() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(JumpToIdentifier.sheet)
    }

    @ViewBuilder
    private var waiting: some View {
        if model.showsStatus {
            Text("\(model.waitingCount) waiting")
                .font(Theme.Text.caption)
                .foregroundStyle(model.waitingCount > 0 ? Theme.status.busy : Theme.text.tertiary)
                .accessibilityElement(children: .ignore)
                .accessibilityValue(String(model.waitingCount))
                .accessibilityIdentifier(JumpToIdentifier.waiting)
        }
    }

    private var explanation: some View {
        Text("tmux does not report agent state, so windows show no status dot.")
            .font(Theme.Text.caption)
            .foregroundStyle(Theme.text.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Space.screenMargin)
            .padding(.bottom, Theme.Space.step2)
            .accessibilityIdentifier(JumpToIdentifier.explanation)
    }

    @ViewBuilder
    private var failure: some View {
        if let state = model.jumpFailure {
            SectionCaption(state.copy.title, tone: Theme.status.attention)
                .padding(.horizontal, Theme.Space.screenMargin)
                .padding(.bottom, Theme.Space.step2)
                .accessibilityIdentifier(JumpToIdentifier.failure)
        }
    }

    private var layoutSwitcher: some View {
        HStack(spacing: Theme.Space.step3) {
            SegmentedPicker(
                options: JumpLayout.allCases.map {
                    SegmentedPicker.Option(id: $0.rawValue, label: $0.label, value: $0)
                },
                selection: model.layout,
                accessibilityIdentifier: { $0.value.identifier },
                select: { model.selectLayout($0) }
            )
            Spacer(minLength: Theme.Space.step2)
            waiting
        }
        .padding(.horizontal, Theme.Space.screenMargin)
        .padding(.bottom, Theme.Space.step3)
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            LoadingView(.screen(label: "Loading windows"))
        } else if model.loadFailed {
            ErrorStateView(state: model.failureState ?? .mux(.attachTargetVanished)) {
                Task { await model.load() }
            }
        } else if model.sessions.isEmpty {
            Text("No windows or tabs on this host")
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            JumpToContent(model: model, onJump: jump)
        }
    }

    private var bytesProbe: some View {
        Text(model.renderedLastBytes)
            .font(Theme.Text.caption)
            .frame(height: 1)
            .clipped()
            .opacity(0)
            .accessibilityIdentifier(JumpToIdentifier.bytes)
    }

    private func jump(_ row: JumpRow) {
        guard !model.isJumping else { return }
        Task {
            guard await model.jump(to: row) else { return }
            onDismiss()
            announce(row)
        }
    }

    private func announce(_ row: JumpRow) {
        guard case .focusedElsewhere(let session) = model.lastOutcome else {
            statusToasts.present(severity: .success, title: "Jumped to \(row.title)")
            return
        }
        statusToasts.present(
            severity: .attention,
            title: MuxNavigationCopy.focused(in: name(of: session)),
            body: MuxNavigationCopy.detachToSwitch
        )
    }

    private func name(of session: MuxSessionID) -> String {
        model.sessions.first { $0.id == session }?.name ?? session.rawValue
    }
}
