import AnySSHCore
import SwiftUI

public struct SessionSwitcherView: View {
    let model: any SessionSwitcherPresenting
    let onSwitch: (SessionID) -> Void
    var onDismiss: (() -> Void)?

    @State var selection = 0
    @FocusState private var isFocused: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init(
        model: any SessionSwitcherPresenting,
        onSwitch: @escaping (SessionID) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.model = model
        self.onSwitch = onSwitch
        self.onDismiss = onDismiss
    }

    var columns: [GridItem] {
        let minimum =
            horizontalSizeClass == .regular
            ? SessionSwitcherMetrics.regularColumn
            : SessionSwitcherMetrics.compactColumn
        return [GridItem(.adaptive(minimum: minimum), spacing: Theme.Space.step3)]
    }

    public var body: some View {
        content
            .background { Theme.surface.base.ignoresSafeArea() }
            .focusable()
            .focused($isFocused)
            .defaultFocus($isFocused, true)
            .keyTraversal(
                onMoveUp: { moveSelection(by: -1) },
                onMoveDown: { moveSelection(by: 1) },
                onActivate: activateSelection,
                onDismiss: { onDismiss?() }
            )
            .onAppear {
                selection = model.activeSessionID.flatMap { model.registry.index(of: $0) } ?? 0
            }
            .task { await model.refreshAgentKinds() }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Sessions")
            .accessibilityIdentifier(SessionSwitcherIdentifier.surface)
    }

    private var header: some View {
        ScreenHeader("Sessions") {
            IconButton(
                systemImage: "plus",
                label: "New session",
                surface: .raised,
                accessibilityIdentifier: SessionSwitcherIdentifier.newSession
            ) {
                Task { await model.openAdditionalSession() }
            }
            .disabled(!model.canOpenAdditionalSession)
            IconButton(
                systemImage: model.isGridMode ? "list.bullet" : "square.grid.2x2",
                label: model.isGridMode ? "Show as a list" : "Show as a grid",
                surface: .raised,
                accessibilityIdentifier: SessionSwitcherIdentifier.mode
            ) {
                model.toggleGridMode()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            header
            if model.registry.isEmpty {
                empty
            } else if model.isGridMode {
                grid
            } else {
                list
            }
            SessionPolicyFooter()
        }
    }

    private var empty: some View {
        Text("No open sessions")
            .font(Theme.Text.body)
            .foregroundStyle(Theme.text.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier(SessionSwitcherIdentifier.empty)
    }
}

enum SessionSwitcherMetrics {
    static let compactColumn: CGFloat = 160
    static let regularColumn: CGFloat = 320
}
