import AnySSHCore
import Foundation

public enum SessionRestoreDocument {
    public static let schemaVersion = 1

    private struct StoredCapabilities: Codable {
        let roaming: Bool
        let serverSideResume: Bool
        let execChannels: Bool
        let portForwarding: Bool

        init(_ capabilities: TransportCapabilities) {
            roaming = capabilities.roaming
            serverSideResume = capabilities.serverSideResume
            execChannels = capabilities.execChannels
            portForwarding = capabilities.portForwarding
        }

        var transportCapabilities: TransportCapabilities {
            TransportCapabilities(
                roaming: roaming,
                serverSideResume: serverSideResume,
                execChannels: execChannels,
                portForwarding: portForwarding
            )
        }
    }

    private struct StoredWorkspace: Codable {
        let path: String
        let provenance: String

        init(_ workspace: WorkspaceLocation) {
            path = workspace.path
            provenance = workspace.provenance.rawValue
        }

        var location: WorkspaceLocation? {
            guard let provenance = WorkspaceLocation.Provenance(rawValue: provenance) else {
                return nil
            }
            return WorkspaceLocation(path: path, provenance: provenance)
        }
    }

    private struct StoredRecord: Codable {
        let id: String
        let remoteID: String
        let connectionID: String
        let title: String
        let capabilities: StoredCapabilities
        let createdAt: TimeInterval
        let lastActiveAt: TimeInterval
        let workspace: StoredWorkspace?

        init(_ record: SessionRecord) {
            id = record.id.rawValue
            remoteID = record.remoteID.rawValue
            connectionID = record.connectionID.rawValue
            title = record.title
            capabilities = StoredCapabilities(record.capabilities)
            createdAt = record.createdAt.timeIntervalSince1970
            lastActiveAt = record.lastActiveAt.timeIntervalSince1970
            workspace = record.workspace.map(StoredWorkspace.init)
        }

        var record: SessionRecord {
            SessionRecord(
                id: SessionID(rawValue: id),
                remoteID: RemoteID(rawValue: remoteID),
                connectionID: ConnectionID(rawValue: connectionID),
                title: title,
                state: .disconnected(.backgrounded),
                capabilities: capabilities.transportCapabilities,
                reconnectAttempts: 0,
                createdAt: Date(timeIntervalSince1970: createdAt),
                lastActiveAt: Date(timeIntervalSince1970: lastActiveAt),
                workspace: workspace?.location
            )
        }
    }

    private struct StoredTranscript: Codable {
        let sessionID: String
        let lines: [String]
    }

    private struct Envelope: Codable {
        let schemaVersion: Int
        let records: [StoredRecord]
        let transcripts: [StoredTranscript]
        let activeSessionID: String?
    }

    private struct VersionProbe: Decodable {
        let schemaVersion: Int
    }

    public static func read(from url: URL) throws -> SessionRestoreSnapshot? {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return nil
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        guard let probe = try? decoder.decode(VersionProbe.self, from: data) else {
            throw SessionRestoreError.unreadable
        }
        guard probe.schemaVersion >= 1, probe.schemaVersion <= schemaVersion else {
            throw SessionRestoreError.unsupportedSchemaVersion(probe.schemaVersion)
        }
        let envelope = try decoder.decode(Envelope.self, from: data)
        let transcripts = Dictionary(
            uniqueKeysWithValues: envelope.transcripts.map { (SessionID(rawValue: $0.sessionID), $0.lines) }
        )
        return SessionRestoreSnapshot(
            records: envelope.records.map(\.record),
            transcripts: transcripts,
            activeSessionID: envelope.activeSessionID.map(SessionID.init(rawValue:))
        )
    }

    public static func write(_ snapshot: SessionRestoreSnapshot, to url: URL) throws {
        let envelope = Envelope(
            schemaVersion: schemaVersion,
            records: snapshot.records.map(StoredRecord.init),
            transcripts: snapshot.transcripts.map {
                StoredTranscript(sessionID: $0.key.rawValue, lines: $0.value)
            },
            activeSessionID: snapshot.activeSessionID?.rawValue
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(envelope)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
        #else
        try data.write(to: url, options: [.atomic])
        #endif
        try protectAndExcludeFromBackup(url)
    }

    private static func protectAndExcludeFromBackup(_ url: URL) throws {
        #if os(iOS)
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: url.path)
        #endif
        var url = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
    }
}
