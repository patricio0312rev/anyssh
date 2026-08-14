import AnySSHCore
import Foundation
import Observation
import SSHTransport

@Observable
public final class RemoteFormModel {
    public let id: RemoteID
    public let isNew: Bool

    public var name = ""
    public var host = ""
    public var port = ""
    public var username = ""
    public var authMethod = AuthMethod.publicKey
    public var password = ""
    public var startPath = ""
    public var startupCommand = ""
    public var tag = ""
    public var deviceType = RemoteDeviceType.unknown
    public private(set) var detectedDeviceType: RemoteDeviceType?
    private var deviceTypeSource = RemoteDeviceTypeSource.automatic

    public private(set) var isValidating = false
    public private(set) var isTesting = false
    public private(set) var testOutcome: ConnectionTestOutcome?
    public private(set) var passwordSaveError: SecretsErrorState?

    public let keyImport: KeyImportModel
    public private(set) var authBridge: SessionAuthBridge?

    private let secrets: any SecretStore
    private let hostKeys: (any HostKeyStore)?

    public init(
        secrets: any SecretStore,
        hostKeys: (any HostKeyStore)? = nil,
        editing remote: Remote? = nil
    ) {
        let identifier = remote?.id ?? RemoteID(rawValue: UUID().uuidString.lowercased())
        self.secrets = secrets
        self.hostKeys = hostKeys
        keyImport = KeyImportModel(remoteID: identifier, secrets: secrets)
        if let remote {
            id = remote.id
            isNew = false
            name = remote.name
            host = remote.host
            port = String(remote.port)
            username = remote.username
            authMethod = remote.authMethod
            startPath = remote.startPath ?? ""
            startupCommand = remote.startupCommand ?? ""
            tag = remote.tag ?? ""
            deviceType = remote.deviceType
            deviceTypeSource = remote.deviceTypeSource
            detectedDeviceType = remote.deviceTypeSource == .detected ? remote.deviceType : nil
        } else {
            id = identifier
            isNew = true
        }
    }

    public var hasImportedKey: Bool {
        if case .saved = keyImport.stage { return true }
        return false
    }

    public var deviceTypeSelection: RemoteDeviceType {
        get { deviceType }
        set {
            deviceType = newValue
            deviceTypeSource = newValue == .unknown ? .automatic : .user
        }
    }

    public var needsKey: Bool {
        authMethod == .publicKey
    }

    public var needsPassword: Bool {
        authMethod == .password
    }

    public var hostMessage: String? {
        isValidating ? RemoteFormValidation.host(host) : nil
    }

    public var portMessage: String? {
        isValidating ? RemoteFormValidation.port(port) : nil
    }

    public var usernameMessage: String? {
        isValidating ? RemoteFormValidation.username(username) : nil
    }

    public var passwordMessage: String? {
        isValidating && needsPassword && isNew
            ? RemoteFormValidation.password(password) : nil
    }

    public var isValid: Bool {
        RemoteFormValidation.host(host) == nil
            && RemoteFormValidation.port(port) == nil
            && RemoteFormValidation.username(username) == nil
            && (!needsPassword || !isNew || RemoteFormValidation.password(password) == nil)
    }

    public var hostKeysAvailable: Bool {
        hostKeys != nil
    }

    public var canTest: Bool {
        !isTesting && isValid && hostKeys != nil
    }

    public func validate() {
        isValidating = true
    }

    public func remote(orderIndex: Int = 0) -> Remote? {
        validate()
        guard isValid else { return nil }
        let address = host.trimmingCharacters(in: .whitespaces)
        return Remote(
            id: id,
            name: trimmed(name) ?? address,
            host: address,
            port: RemoteFormValidation.resolvedPort(port),
            username: username.trimmingCharacters(in: .whitespaces),
            authMethod: authMethod,
            startPath: trimmed(startPath),
            startupCommand: trimmed(startupCommand),
            tag: trimmed(tag),
            orderIndex: orderIndex,
            deviceType: deviceType,
            deviceTypeSource: deviceTypeSource
        )
    }

    public func applyDetection(_ capabilities: HostCapabilities) {
        let detected = capabilities.detectedDeviceType
        guard deviceTypeSource != .user, detected != .unknown else { return }
        detectedDeviceType = detected
        deviceType = detected
        deviceTypeSource = .detected
    }

    public func savePasswordIfNeeded() async -> Bool {
        passwordSaveError = nil
        guard needsPassword else { return true }
        let value = password
        guard !value.isEmpty else { return true }
        do {
            try await secrets.store(
                Data(value.utf8),
                at: SecretReference(remoteID: id, kind: .password)
            )
            password = ""
            return true
        } catch let error as SecretStoreError {
            passwordSaveError = error.state
            return false
        } catch {
            passwordSaveError = .keychainWriteDenied
            return false
        }
    }

    public func testConnection() async {
        guard let remote = remote(), let hostKeys else { return }
        isTesting = true
        testOutcome = nil
        let bridge = SessionAuthBridge(remote: remote, secrets: secrets, hostKeys: hostKeys)
        authBridge = bridge
        let override = needsPassword ? password : nil
        testOutcome = await ConnectionTest.run(
            remote: remote,
            secrets: secrets,
            hostKeys: hostKeys,
            passwordOverride: override,
            answering: bridge.answering,
            delegate: bridge.delegate
        )
        isTesting = false
    }

    public func dismissTestOutcome() {
        testOutcome = nil
        authBridge = nil
    }

    private func trimmed(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}
