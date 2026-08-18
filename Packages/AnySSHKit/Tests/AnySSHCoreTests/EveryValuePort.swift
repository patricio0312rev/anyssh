import Foundation
import Testing

@testable import AnySSHCore

struct EveryValuePort: RemoteStore, SecretStore, HostKeyStore, ReachabilityProbe, ByteSink,
    RemoteCommandRunner, CapabilityProbe, RecentDirectoriesProbe, GitService, BlobService,
    MultiplexerAdapter, WorkspacePathResolver, SyntaxHighlighter, Clock, IDProvider,
    TerminalTransportDelegate, UserFacingError
{
    var kind: MultiplexerKind { fatalError() }
    var capabilities: MultiplexerCapabilities { fatalError() }
    var now: Date { fatalError() }
    var stateID: String { fatalError() }

    func remotes() async throws -> [Remote] { fatalError() }
    func save(_ remote: Remote) async throws { fatalError() }
    func delete(_ id: RemoteID) async throws { fatalError() }
    func reorder(to order: [RemoteID]) async throws { fatalError() }
    func move(fromOffsets source: IndexSet, toOffset destination: Int) async throws { fatalError() }

    func secret(_ reference: SecretReference) async throws -> Data? { fatalError() }
    func store(_ secret: Data, at reference: SecretReference) async throws { fatalError() }
    func remove(_ reference: SecretReference) async throws { fatalError() }

    func knownKey(host: String, port: Int) async throws -> HostKey? { fatalError() }
    func remember(_ key: HostKey, host: String, port: Int) async throws { fatalError() }
    func forget(host: String, port: Int) async throws { fatalError() }

    func probe(_ remote: Remote) async -> Reachability { fatalError() }
    func probe() async throws -> HostCapabilities { fatalError() }
    func list(limit: Int) async throws -> [RecentDirectory] { fatalError() }

    func ingest(_ bytes: ArraySlice<UInt8>) async { fatalError() }
    func run(_ batch: RemoteBatch) async throws -> BatchResponse { fatalError() }

    func repository(at location: WorkspaceLocation) async throws -> RepositoryRef { fatalError() }
    func status(of repository: RepositoryRef) async throws -> RepositoryStatus { fatalError() }
    func diff(
        for file: ChangedFile,
        in repository: RepositoryRef,
        staged: Bool
    ) async throws -> FileDiff { fatalError() }
    func history(
        of repository: RepositoryRef,
        before: CommitID?,
        limit: Int
    ) async throws -> [Commit] { fatalError() }
    func diff(for commit: CommitID, in repository: RepositoryRef) async throws -> [FileDiff] {
        fatalError()
    }
    func diff(forUntracked path: String, in repository: RepositoryRef) async throws -> FileDiff {
        fatalError()
    }

    func metadata(for refs: [BlobRef]) async throws -> [BlobMetadata] { fatalError() }
    func fetch(_ ref: BlobRef, intent: BlobIntent) async throws -> FetchedBlob { fatalError() }

    func detect() async throws -> MultiplexerInfo { fatalError() }
    func listSessions() async throws -> [MuxSession] { fatalError() }
    func snapshot(_ session: MuxSession.ID) async throws -> MuxSnapshot { fatalError() }
    func readPane(_ pane: MuxPane.ID, lines: Int) async throws -> String { fatalError() }
    func keyBindings() async throws -> MuxKeyBindings { fatalError() }
    func focus(_ target: MuxTarget) async throws { fatalError() }
    func attachCommand(_ target: MuxTarget) -> String { fatalError() }

    func resolve(_ session: SessionRecord) async -> WorkspaceLocation? { fatalError() }
    func tokens(for blob: String, language: LanguageID) async -> [LineTokens] { fatalError() }
    func next() -> String { fatalError() }

    func transport(
        _ transport: any TerminalTransport,
        verify key: HostKey,
        status: KnownHostStatus
    ) async -> HostKeyVerdict { fatalError() }
    func transport(
        _ transport: any TerminalTransport,
        answer round: AuthPromptRound
    ) async -> AuthPromptAnswer { fatalError() }
    func transport(_ transport: any TerminalTransport, didChange state: TransportState) async {
        fatalError()
    }
}

private actor EveryActorPort: TerminalTransport {
    nonisolated var kind: TransportKind { fatalError() }
    nonisolated var capabilities: TransportCapabilities { fatalError() }
    var state: TransportState { fatalError() }

    func setDelegate(_ delegate: any TerminalTransportDelegate) { fatalError() }
    func setSink(_ sink: any ByteSink) { fatalError() }
    func start(size: TerminalSize) async throws { fatalError() }
    func send(_ bytes: ArraySlice<UInt8>) async throws { fatalError() }
    func resize(to size: TerminalSize) async throws { fatalError() }
    func close() async { fatalError() }
}

private actor EveryConnectionPort: RemoteConnection {
    nonisolated var connectionID: ConnectionID { fatalError() }
    var displayState: TransportState { fatalError() }
    var controlState: TransportState { fatalError() }
    var openChannelCount: Int { fatalError() }
    var clientPort: Int? { nil }

    func run(_ batch: RemoteBatch) async throws -> BatchResponse { fatalError() }
    func cancelAll(reason: DisconnectReason) async { fatalError() }
    func close(reason: DisconnectReason) async { fatalError() }
    func attachDisplay(sink: any ByteSink, size: TerminalSize) async throws { fatalError() }
    func setDisplayDelegate(_ delegate: any TerminalTransportDelegate) async { fatalError() }
    func sendDisplay(_ bytes: ArraySlice<UInt8>) async throws { fatalError() }
    func resizeDisplay(to size: TerminalSize) async throws { fatalError() }
    func send(_ bytes: ArraySlice<UInt8>) async throws { fatalError() }
}

@MainActor
private final class EveryEnginePort: TerminalEngine, TerminalEngineDelegate {
    var size: TerminalSize { fatalError() }

    func setDelegate(_ delegate: any TerminalEngineDelegate) { fatalError() }
    func feed(_ bytes: ArraySlice<UInt8>) { fatalError() }
    func resize(to size: TerminalSize) { fatalError() }
    func setScrollbackLimit(_ lines: Int) { fatalError() }

    func engine(_ engine: any TerminalEngine, didChangeTitle title: String) { fatalError() }
    func engine(_ engine: any TerminalEngine, didReportWorkingDirectory path: String) {
        fatalError()
    }
    func engine(_ engine: any TerminalEngine, didRequestClipboardWrite text: String) {
        fatalError()
    }
    func engineDidRequestClipboardRead(_ engine: any TerminalEngine) -> String? { fatalError() }
    func engineDidRing(_ engine: any TerminalEngine) { fatalError() }
    func engine(_ engine: any TerminalEngine, didProduceInput bytes: ArraySlice<UInt8>) {
        fatalError()
    }
    func engine(_ engine: any TerminalEngine, didResizeTo size: TerminalSize) { fatalError() }
}
