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
        VStack(spacing: 0) {
            header
            layoutSwitcher
            if model.kind == .tmux {
                explanation
            }
            content
            bytesProbe
        }
        .background { Theme.surface.base.ignoresSafeArea() }
        .task { await model.load() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(JumpToIdentifier.sheet)
    }

    private var header: some View {
        ScreenHeader("Jump to") {
            if model.showsStatus {
                Text("\(model.waitingCount) waiting")
                    .font(Theme.Text.caption)
                    .foregroundStyle(
                        model.waitingCount > 0 ? Theme.status.busy : Theme.text.tertiary
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityValue(String(model.waitingCount))
                    .accessibilityIdentifier(JumpToIdentifier.waiting)
            }
            CloseButton(accessibilityIdentifier: JumpToIdentifier.close, action: onDismiss)
        }
        .accessibilityIdentifier(JumpToIdentifier.title)
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

    private var layoutSwitcher: some View {
        SegmentedPicker(
            options: JumpLayout.allCases.map {
                SegmentedPicker.Option(id: $0.rawValue, label: $0.label, value: $0)
            },
            selection: model.layout,
            accessibilityIdentifier: { $0.value.identifier },
            select: { model.selectLayout($0) }
        )
        .frame(maxWidth: .infinity, alignment: .leading)
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
        Task {
            if await model.jump(to: row) {
                statusToasts.present(severity: .success, title: "Jumped to \(row.title)")
            } else {
                statusToasts.present(state: .mux(.attachTargetVanished))
            }
        }
    }
}
