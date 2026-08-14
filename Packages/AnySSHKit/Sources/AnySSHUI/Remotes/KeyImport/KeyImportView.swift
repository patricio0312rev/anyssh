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
            Button(action: model.importPastedKey) {
                Label("Paste Key", systemImage: "key")
            }
            .buttonStyle(.rowAction)
            .accessibilityIdentifier(UIIdentifier.KeyImport.paste)
            Button {
                isPickingFile = true
            } label: {
                Label("Choose File", systemImage: "folder")
            }
            .buttonStyle(.rowAction)
            .accessibilityIdentifier(UIIdentifier.KeyImport.file)
        } header: {
            SectionLabel("Source")
        } footer: {
            SectionCaption(
                "Paste a private key, or pick the file it lives in. The key is stored on this "
                    + "device and never leaves it."
            )
        }
        .formCardSection()
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
            SectionCaption("This key is encrypted. Its passphrase is stored beside it.")
        }
        .formCardSection()
    }

    private var actions: some View {
        Section {
            Button("Save Key") { Task { await model.save() } }
                .buttonStyle(.rowAction(tint: Theme.accent))
                .disabled(!model.canSave)
                .accessibilityIdentifier(UIIdentifier.KeyImport.save)
            Button("Discard", role: .destructive, action: model.discard)
                .buttonStyle(.rowAction(tint: Theme.destructive))
                .accessibilityIdentifier(UIIdentifier.KeyImport.discard)
        }
        .formCardSection()
    }
}
