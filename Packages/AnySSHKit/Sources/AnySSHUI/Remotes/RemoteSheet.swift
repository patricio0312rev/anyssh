import AnySSHCore
import SwiftUI

enum RemoteFormDestination: Hashable {
    case keyImport
}

struct RemoteSheet: View {
    @State private var model: RemoteFormModel
    @State private var path: [RemoteFormDestination]

    private let save: (Remote) async -> Void
    private let dismiss: () -> Void

    init(
        route: RemoteRoute,
        secrets: any SecretStore,
        hostKeys: (any HostKeyStore)? = nil,
        save: @escaping (Remote) async -> Void,
        dismiss: @escaping () -> Void
    ) {
        _model = State(
            wrappedValue: RemoteFormModel(
                secrets: secrets,
                hostKeys: hostKeys,
                editing: route.remote
            )
        )
        _path = State(wrappedValue: route == .importKey ? [.keyImport] : [])
        self.save = save
        self.dismiss = dismiss
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.surface.base.ignoresSafeArea()
                RemoteFormView(model: model, save: save, cancel: dismiss)
            }
            .navigationDestination(for: RemoteFormDestination.self) { _ in
                ZStack {
                    Theme.surface.base.ignoresSafeArea()
                    KeyImportView(model: model.keyImport)
                }
            }
        }
        .tint(Theme.accent)
    }
}
