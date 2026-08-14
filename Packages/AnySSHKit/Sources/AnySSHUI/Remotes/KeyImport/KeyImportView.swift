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
        VStack(alignment: .leading, spacing: Theme.Space.step5) {
            sources
            content
            Spacer(minLength: 0)
        }
        .padding(Theme.Space.step5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Import Key")
        .overlay(alignment: .topLeading) { ScreenMarker(identifier: UIIdentifier.KeyImport.screen) }
        .fileImporter(
            isPresented: $isPickingFile,
            allowedContentTypes: [.data, .text],
            onCompletion: model.importPickedFile
        )
    }

    private var sources: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step3) {
            Text(
                "Paste a private key, or pick the file it lives in. The key is stored on this "
                    + "device and never leaves it."
            )
            .font(Theme.Text.body)
            .foregroundStyle(Theme.text.secondary)

            HStack(spacing: Theme.Space.step3) {
                Button("Paste Key", action: model.importPastedKey)
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .accessibilityIdentifier(UIIdentifier.KeyImport.paste)
                Button("Choose File") { isPickingFile = true }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .accessibilityIdentifier(UIIdentifier.KeyImport.file)
            }
            .controlSize(.large)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.stage {
        case .idle:
            EmptyView()
        case .inspected(let key):
            inspection(of: key)
        case .saved(let key):
            KeyImportSummary(key: key, isSaved: true)
        case .refused(let refusal):
            KeyImportRefusalView(refusal: refusal, dismiss: model.discard)
        }
    }

    private func inspection(of key: KeyMaterial) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.step5) {
            KeyImportSummary(key: key, isSaved: false)

            if model.needsPassphrase {
                VStack(alignment: .leading, spacing: Theme.Space.step2) {
                    Text("This key is encrypted. Its passphrase is stored beside it.")
                        .font(Theme.Text.caption)
                        .foregroundStyle(Theme.text.secondary)
                    SecureField("Passphrase", text: $model.passphrase)
                        .textContentType(.password)
                        .accessibilityIdentifier(UIIdentifier.KeyImport.passphrase)
                }
            }

            HStack(spacing: Theme.Space.step3) {
                Button("Save Key") { Task { await model.save() } }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .disabled(!model.canSave)
                    .accessibilityIdentifier(UIIdentifier.KeyImport.save)
                Button("Discard", role: .destructive, action: model.discard)
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .accessibilityIdentifier(UIIdentifier.KeyImport.discard)
            }
            .controlSize(.large)
        }
    }
}
