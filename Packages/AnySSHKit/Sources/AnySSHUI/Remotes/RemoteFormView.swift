import AnySSHCore
import SwiftUI

public struct RemoteFormView: View {
    @Bindable private var model: RemoteFormModel

    private let save: (Remote) async -> Void
    private let cancel: () -> Void

    public init(
        model: RemoteFormModel,
        save: @escaping (Remote) async -> Void,
        cancel: @escaping () -> Void
    ) {
        _model = Bindable(wrappedValue: model)
        self.save = save
        self.cancel = cancel
    }

    public var body: some View {
        Form {
            connection
            RemoteFormDeviceSection(model: model)
            authentication
            startup
            if model.hostKeysAvailable {
                RemoteFormTestSection(model: model)
            }
        }
        .scrollContentBackground(.hidden)
        .background { Theme.surface.base.ignoresSafeArea() }
        .navigationTitle(model.isNew ? "Add Host" : "Edit Host")
        .accessibilityIdentifier(UIIdentifier.RemoteForm.screen)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: cancel)
                    .accessibilityIdentifier(UIIdentifier.RemoteForm.cancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        guard let remote = model.remote() else { return }
                        guard await model.savePasswordIfNeeded() else { return }
                        await save(remote)
                    }
                } label: {
                    Text("Save").foregroundStyle(Theme.accent)
                }
                .accessibilityIdentifier(UIIdentifier.RemoteForm.save)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { model.authBridge?.auth.round != nil },
                set: { _ in }
            )
        ) {
            if let bridge = model.authBridge {
                AuthPromptSheet(model: bridge.auth)
                    .interactiveDismissDisabled()
            }
        }
        .sheet(
            isPresented: Binding(
                get: {
                    if case .asking = model.authBridge?.trust.stage { return true }
                    return false
                },
                set: { _ in }
            )
        ) {
            if let bridge = model.authBridge {
                HostKeyTrustView(model: bridge.trust)
            }
        }
    }

    private var connection: some View {
        Section {
            RemoteFormField(
                title: "Host",
                identifier: UIIdentifier.RemoteForm.host,
                text: $model.host,
                message: model.hostMessage,
                placeholder: "build-box.tail1234.ts.net",
                keyboard: .address
            )
            RemoteFormField(
                title: "User",
                identifier: UIIdentifier.RemoteForm.username,
                text: $model.username,
                message: model.usernameMessage,
                placeholder: "patricio"
            )
            RemoteFormField(
                title: "Port",
                identifier: UIIdentifier.RemoteForm.port,
                text: $model.port,
                message: model.portMessage,
                placeholder: "22",
                keyboard: .number
            )
            RemoteFormField(
                title: "Name",
                identifier: UIIdentifier.RemoteForm.name,
                text: $model.name,
                message: nil,
                placeholder: "Optional, defaults to the host"
            )
        } header: {
            SectionLabel("Connection")
        }
        .listRowBackground(Theme.surface.raised)
    }

    private var authentication: some View {
        Section {
            Picker("Method", selection: $model.authMethod) {
                ForEach(AuthMethod.allCases, id: \.self) { method in
                    Text(method.label).tag(method)
                }
            }
            .tint(Theme.text.secondary)
            .accessibilityIdentifier(UIIdentifier.RemoteForm.authMethod)

            if model.needsKey {
                if model.hasImportedKey {
                    Label("Key saved to this device", systemImage: "checkmark.seal")
                        .font(Theme.Text.body)
                        .foregroundStyle(Theme.status.online)
                        .accessibilityIdentifier(UIIdentifier.RemoteForm.keyImported)
                } else {
                    NavigationLink(value: RemoteFormDestination.keyImport) {
                        Label("Import Key", systemImage: "key")
                    }
                    .accessibilityIdentifier(UIIdentifier.RemoteForm.importKey)
                }
            }

            if model.needsPassword {
                RemoteFormField(
                    title: "Password",
                    identifier: UIIdentifier.RemoteForm.password,
                    text: $model.password,
                    message: model.passwordMessage,
                    placeholder: "Required",
                    keyboard: .password
                )
            }
        } header: {
            SectionLabel("Authentication")
        }
        .listRowBackground(Theme.surface.raised)
    }

    private var startup: some View {
        Section {
            RemoteFormField(
                title: "Directory",
                identifier: UIIdentifier.RemoteForm.startPath,
                text: $model.startPath,
                message: nil,
                placeholder: "~/Sites"
            )
            RemoteFormField(
                title: "Command",
                identifier: UIIdentifier.RemoteForm.startupCommand,
                text: $model.startupCommand,
                message: nil,
                placeholder: "tmux attach || tmux new"
            )
            RemoteFormField(
                title: "Tag",
                identifier: UIIdentifier.RemoteForm.tag,
                text: $model.tag,
                message: nil,
                placeholder: "work"
            )
        } header: {
            SectionLabel("Startup")
        }
        .listRowBackground(Theme.surface.raised)
    }
}
