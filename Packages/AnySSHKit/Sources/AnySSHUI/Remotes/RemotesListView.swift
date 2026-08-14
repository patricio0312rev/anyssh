#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct RemotesListView: View {
    @State private var model: RemotesListModel
    @State private var reachability: ReachabilityStatusModel
    @State private var route: RemoteRoute?
    @State private var pendingDeletion: Remote?
    @State private var isReordering = false
    @State private var isPresentingSettings = false

    private let secrets: any SecretStore
    private let hostKeys: (any HostKeyStore)?
    private let onOpen: ((Remote) -> Void)?

    public init(
        store: any RemoteStore,
        secrets: any SecretStore,
        hostKeys: (any HostKeyStore)? = nil,
        probe: any ReachabilityProbe,
        onOpen: ((Remote) -> Void)? = nil
    ) {
        _model = State(wrappedValue: RemotesListModel(store: store, secrets: secrets))
        _reachability = State(wrappedValue: ReachabilityStatusModel(probe: probe))
        self.secrets = secrets
        self.hostKeys = hostKeys
        self.onOpen = onOpen
    }

    public var body: some View {
        NavigationStack {
            content
                .settingsButton(floatsOverContent: hasRows) { isPresentingSettings = true }
                .navigationTitle("Remotes")
                .remotesChrome(
                    isReordering: $isReordering,
                    canAdd: !model.remotes.isEmpty,
                    canReorder: model.remotes.count > 1,
                    add: { route = .add }
                )
        }
        .task { await model.load() }
        .onChange(of: model.remotes) { _, remotes in
            Task { await reachability.update(remotes: remotes) }
        }
        .reachabilityLifecycle(reachability)
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView(layoutDirectory: AppDirectories.support)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $route) { route in
            RemoteSheet(
                route: route,
                secrets: secrets,
                hostKeys: hostKeys,
                save: save,
                dismiss: { self.route = nil }
            )
        }
        .confirmationDialog(
            "Delete \(pendingDeletion?.name ?? "")",
            isPresented: $pendingDeletion.isPresent(),
            titleVisibility: .visible
        ) {
            Button("Delete Host", role: .destructive, action: confirmDeletion)
                .accessibilityIdentifier(UIIdentifier.Remote.deleteConfirm)
            Button("Keep", role: .cancel) { pendingDeletion = nil }
                .accessibilityIdentifier(UIIdentifier.Remote.deleteCancel)
        } message: {
            Text("The host and any key, password or passphrase saved for it are removed.")
        }
        .remoteSecretRefusal(model.refusal, dismiss: model.dismissRefusal)
    }

    private var hasRows: Bool {
        if case .loaded(let remotes) = model.state { return !remotes.isEmpty }
        return false
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            LoadingView(.screen(label: "Loading remotes"))
                .background(Theme.surface.base)
                .accessibilityIdentifier(UIIdentifier.Remote.loading)
        case .loaded(let remotes) where remotes.isEmpty:
            RemotesEmptyState(addHost: { route = .add }, importKey: { route = .importKey })
        case .loaded(let remotes):
            list(remotes)
        case .failed(let message):
            RemotesFailureState(message: message)
        }
    }

    private func list(_ remotes: [Remote]) -> some View {
        List {
            ForEach(remotes) { remote in
                RemoteRow(remote: remote, reachability: reachability.presentation(for: remote.id))
                    .contentShape(.rect)
                    .onTapGesture { open(remote) }
                    .catalogRowChrome()
                    .swipeActions(edge: .trailing) {
                        CatalogSwipe.destructive(
                            title: "Delete",
                            systemImage: "trash",
                            accessibilityIdentifier: UIIdentifier.Remote.delete(remote.id.rawValue)
                        ) {
                            pendingDeletion = remote
                        }

                        CatalogSwipe.accent(
                            title: "Edit",
                            systemImage: "square.and.pencil",
                            accessibilityIdentifier: UIIdentifier.Remote.editRow(remote.id.rawValue)
                        ) {
                            route = .edit(remote)
                        }
                    }
            }
            .onMove { source, destination in
                Task { await model.move(fromOffsets: source, toOffset: destination) }
            }
        }
        .catalogListSurface()
        .accessibilityIdentifier(UIIdentifier.Remote.list)
    }

    private func open(_ remote: Remote) {
        if let onOpen {
            onOpen(remote)
        } else {
            route = .edit(remote)
        }
    }

    private func save(_ remote: Remote) async {
        route = nil
        await model.save(remote)
    }

    private func confirmDeletion() {
        guard let remote = pendingDeletion else { return }
        pendingDeletion = nil
        Task { await model.delete(remote.id) }
    }
}

extension Binding {
    func isPresent<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { if !$0 { wrappedValue = nil } }
        )
    }
}
#endif
