import AnySSHCore
import SwiftUI
import UniformTypeIdentifiers

public struct KeyImportView: View {
    @State private var model: KeyImportModel
    @State private var isPickingFile = false

    public init(model: KeyImportModel) {
        _model = State(wrappedValue: model)
    }

    public init(remoteID: RemoteID, secrets: any SecretStore) {
        self.init(model: KeyImportModel(remoteID: remoteID, secrets: secrets))
    }

    public var body: some View {
        Form {
            source
            content
        }
        .scrollContentBackground(.hidden)
        .background { Theme.surface.base.ignoresSafeArea() }
        .navigationTitle("Import Key")
        .overlay(alignment: .topLeading) { ScreenMarker(identifier: UIIdentifier.KeyImport.screen) }
        .fileImporter(
            isPresented: $isPickingFile,
            allowedContentTypes: [.data, .text],
            onCompletion: model.importPickedFile
        )
    }

    private var source: some View {
        Section {
            Button("Paste Key", action: model.importPastedKey)
                .buttonStyle(.rowAction)
                .accessibilityIdentifier(UIIdentifier.KeyImport.paste)
            Button("Choose File") { isPickingFile = true }
                .buttonStyle(.rowAction)
                .accessibilityIdentifier(UIIdentifier.KeyImport.file)
        } header: {
            SectionLabel("Source")
        } footer: {
            Text(
                "Paste a private key, or pick the file it lives in. The key is stored on this "
                    + "device and never leaves it."
            )
            .font(Theme.Text.caption)
            .foregroundStyle(Theme.text.secondary)
        }
        .listRowBackground(Theme.surface.raised)
    }

    @ViewBuilder
    private var content: some View {
        switch model.stage {
        case .idle:
            EmptyView()
        case .inspected(let key):
            KeyImportSummary(key: key, isSaved: false)
            if model.needsPassphrase {
                passphrase
            }
            actions
        case .saved(let key):
            KeyImportSummary(key: key, isSaved: true)
        case .refused(let refusal):
            KeyImportRefusalView(refusal: refusal, dismiss: model.discard)
        }
    }

    private var passphrase: some View {
        Section {
            SecureField("Passphrase", text: $model.passphrase)
                .textContentType(.password)
                .accessibilityIdentifier(UIIdentifier.KeyImport.passphrase)
        } header: {
            SectionLabel("Passphrase")
        } footer: {
            Text("This key is encrypted. Its passphrase is stored beside it.")
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
        }
        .listRowBackground(Theme.surface.raised)
    }

    private var actions: some View {
        Section {
            Button("Save Key") { Task { await model.save() } }
                .buttonStyle(.rowAction)
                .disabled(!model.canSave)
                .accessibilityIdentifier(UIIdentifier.KeyImport.save)
            Button("Discard", role: .destructive, action: model.discard)
                .buttonStyle(.rowAction(tint: Theme.destructive))
                .accessibilityIdentifier(UIIdentifier.KeyImport.discard)
        }
        .listRowBackground(Theme.surface.raised)
    }
}
