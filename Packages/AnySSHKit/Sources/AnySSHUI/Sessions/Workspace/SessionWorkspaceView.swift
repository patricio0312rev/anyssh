#if canImport(UIKit)
import AnySSHCore
import SwiftUI
import TerminalEmulator

public struct SessionWorkspaceView: View {
    @State var model: SessionWorkspaceModel
    @State var isSwitcherPresented = false
    @State var isPalettePresented = false
    @State var presentedBrowser: WorkspaceBrowserMode?
    @State var isSnippetsPresented = false
    @State var isMultiplexerPresented = false
    @State var isJumpToPresented = false
    @State var isImportingFile = false
    @State var dictation = DictationEngine()
    @State var fileImport = FileImportModel()
    @State var switchEdge = Edge.trailing
    @State var commandRegistry = AppCommandRegistry(commands: [])
    @State private var keyboard = KeyboardVisibility()
    @Environment(\.statusToasts) var toasts

    let onClose: (() -> Void)?
    private let initialSurface: WorkspaceSurface?
    private let hostsToasts: Bool

    public init(
        model: SessionWorkspaceModel,
        initialSurface: WorkspaceSurface? = nil,
        hostsToasts: Bool = false,
        onClose: (() -> Void)? = nil
    ) {
        _model = State(wrappedValue: model)
        self.initialSurface = initialSurface
        self.hostsToasts = hostsToasts
        self.onClose = onClose
    }

    private func present(_ surface: WorkspaceSurface) {
        switch surface {
        case .switcher:
            isSwitcherPresented = true
        case .palette:
            isPalettePresented = true
        case .changes:
            presentedBrowser = .changes
        case .files:
            presentedBrowser = .files
        }
    }

    public var body: some View {
        stack
            .workspaceSheets(
                model: model,
                isMultiplexerPresented: $isMultiplexerPresented,
                isJumpToPresented: $isJumpToPresented
            )
            .sheet(isPresented: $isSnippetsPresented) {
                SnippetsSheet { text in send(text) }
            }
            .sheet(item: $presentedBrowser) { mode in
                browserSheet(mode)
                    .presentationDragIndicator(.visible)
                    .task { await model.resolveWorkspaceForActiveSession() }
            }
            .sessionReconnectLifecycle(model)
            .overlay(alignment: .bottom) {
                if hostsToasts { StatusToastHost(center: toasts) }
            }
            .onAppear { model.statusToasts = toasts }
            .privacyCover()
    }

    private var stack: some View {
        NavigationStack {
            ZStack {
                content
                switcherOverlay
                paletteOverlay
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if showsAccessoryBar { accessoryBar }
            }
            .fileImporter(
                isPresented: $isImportingFile,
                allowedContentTypes: [.item],
                onCompletion: importPicked
            )
            .background { Theme.surface.base.ignoresSafeArea() }
            .background { switchDurationProbe }
            .animation(Theme.Motion.sessionSwitch, value: model.activeSessionID)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                installCommands()
                if let initialSurface { present(initialSurface) }
            }
            .onChange(of: model.shouldPresentSwitcher) { _, wants in
                guard wants else { return }
                isSwitcherPresented = true
                Task { @MainActor in model.shouldPresentSwitcher = false }
            }
            .toolbar {
                SessionWorkspaceToolbar(
                    title: model.activeRecord?.title ?? Self.fallbackTitle,
                    transportState: model.activeTransportState,
                    keyboardEngine: model.activeSessionID.flatMap { model.surface(for: $0)?.engine },
                    workspacePath: model.activeRecord?.workspace?.path,
                    showsBack: onClose != nil,
                    onBack: dismissToRemotes,
                    onOpenSwitcher: presentSwitcher,
                    onOpenBrowser: { presentedBrowser = .changes }
                )
            }
            .toolbarBackground(Theme.surface.base, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let failure = model.openFailure, model.activeSessionID == nil {
            openFailure(failure)
        } else if let active = model.activeSessionID, let surface = model.surface(for: active) {
            ZStack {
                terminal(surface)
                    .id(surface.sessionID)
                    .transition(switchTransition)
                if let failure = model.openFailure {
                    openFailure(failure)
                }
            }
        } else {
            empty
        }
    }

    private var switchTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: switchEdge),
            removal: .move(edge: switchEdge == .trailing ? .leading : .trailing)
        )
    }

    private var showsAccessoryBar: Bool {
        keyboard.isVisible
            && model.activeSessionID != nil
            && !isSwitcherPresented
            && !isPalettePresented
            && presentedBrowser == nil
    }

    @ViewBuilder
    var accessoryBar: some View {
        if let id = model.activeSessionID, let bar = model.barModels[id] {
            AccessoryBar(
                model: bar,
                isDictating: dictation.isListening,
                onDictate: toggleDictation,
                onImportFile: { isImportingFile = true },
                onOpenSnippets: { isSnippetsPresented = true },
                onOpenMultiplexer: model.showsMultiplexer ? { isMultiplexerPresented = true } : nil,
                onOpenJumpTo: model.showsMultiplexer ? { isJumpToPresented = true } : nil
            )
            .id(id)
        }
    }

    private func installCommands() {
        commandRegistry.replace(
            with: AppCommandBinding.workspaceCommands(
                model: model,
                onNewConnection: dismissToRemotes,
                onOpenSwitcher: presentSwitcher,
                onOpenPalette: { isPalettePresented = true },
                onOpenChanges: { presentedBrowser = .changes },
                onOpenJumpTo: { isJumpToPresented = true }
            )
        )
    }

    private var switchDurationProbe: some View {
        Text(
            SessionSwitchSignpost.measured
                .map { String(format: "%.1f", $0) }
                .joined(separator: ",")
        )
        .font(Theme.Text.caption)
        .frame(width: 1, height: 1)
        .clipped()
        .opacity(0)
        .accessibilityIdentifier(UIIdentifier.Session.switchDurations)
        .id(model.activeSessionID)
    }

    static let fallbackTitle = "Sessions"
}
#endif
