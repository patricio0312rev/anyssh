import AnySSHCore
import Foundation
import Observation

@Observable
@MainActor
public final class KeyImportModel {
    public enum Stage: Equatable {
        case idle
        case inspected(KeyMaterial)
        case saved(KeyMaterial)
        case refused(KeyImportRefusal)
    }

    public private(set) var stage: Stage = .idle

    public var passphrase = ""

    private let remoteID: RemoteID
    private let secrets: any SecretStore
    private let pasteboard: any KeyImportPasteboard

    @ObservationIgnored private var pending: KeyMaterialBuffer?

    public init(
        remoteID: RemoteID,
        secrets: any SecretStore,
        pasteboard: any KeyImportPasteboard = SystemKeyImportPasteboard()
    ) {
        self.remoteID = remoteID
        self.secrets = secrets
        self.pasteboard = pasteboard
    }

    public var key: KeyMaterial? {
        switch stage {
        case .inspected(let key), .saved(let key): key
        case .idle, .refused: nil
        }
    }

    public var needsPassphrase: Bool {
        guard case .inspected(let key) = stage else { return false }
        return key.isEncrypted
    }

    public var canSave: Bool {
        guard case .inspected(let key) = stage else { return false }
        return !key.isEncrypted || !passphrase.isEmpty
    }

    public func importPastedKey() {
        discard()
        guard let text = pasteboard.read(), !text.isEmpty else {
            stage = .refused(.key(.nothingToImport))
            return
        }
        if inspect(KeyMaterialBuffer(text: text)) {
            pasteboard.clear()
        }
    }

    public func importPickedFile(_ result: Result<URL, any Error>) {
        discard()
        guard case .success(let url) = result else { return }
        do {
            inspect(try KeyImportFileReader.read(url))
        } catch let error as KeyMaterialError {
            stage = .refused(.key(error))
        } catch {
            stage = .refused(.key(.nothingToImport))
        }
    }

    public func save() async {
        guard case .inspected(let key) = stage, canSave, let buffer = pending else { return }
        do {
            try await store(buffer.data(), as: .privateKey)
            if key.isEncrypted {
                try await store(Data(passphrase.utf8), as: .keyPassphrase)
            }
            stage = .saved(key)
        } catch let error as SecretStoreError {
            stage = .refused(.secrets(error))
        } catch {
            stage = .refused(.secrets(.writeDenied))
        }
        discardPlaintext()
    }

    public func discard() {
        discardPlaintext()
        stage = .idle
    }

    @discardableResult
    private func inspect(_ buffer: KeyMaterialBuffer) -> Bool {
        do {
            let key = try KeyMaterialParser.parse(buffer)
            pending = buffer
            stage = .inspected(key)
            return true
        } catch let error as KeyMaterialError {
            buffer.zero()
            stage = .refused(.key(error))
            return error.sawKeyMaterial
        } catch {
            buffer.zero()
            stage = .refused(.key(.nothingToImport))
            return false
        }
    }

    private func store(_ secret: Data, as kind: SecretKind) async throws {
        var payload = secret
        defer { payload.resetBytes(in: 0..<payload.count) }
        try await secrets.store(payload, at: SecretReference(remoteID: remoteID, kind: kind))
    }

    private func discardPlaintext() {
        pending?.zero()
        pending = nil
        passphrase = ""
    }
}
