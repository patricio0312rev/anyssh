import Foundation
import Testing

@testable import AnySSHCore

private func requireSendable<T: Sendable>(_ type: T.Type) -> Bool {
    true
}

@Suite struct PortConformanceTests {
    @Test func everyPortIsSendable() {
        #expect(requireSendable((any RemoteStore).self))
        #expect(requireSendable((any SecretStore).self))
        #expect(requireSendable((any HostKeyStore).self))
        #expect(requireSendable((any ReachabilityProbe).self))
        #expect(requireSendable((any TerminalTransport).self))
        #expect(requireSendable((any RemoteConnection).self))
        #expect(requireSendable((any TerminalTransportDelegate).self))
        #expect(requireSendable((any ByteSink).self))
        #expect(requireSendable((any TerminalEngine).self))
        #expect(requireSendable((any TerminalEngineDelegate).self))
        #expect(requireSendable((any RemoteCommandRunner).self))
        #expect(requireSendable((any CapabilityProbe).self))
        #expect(requireSendable((any RecentDirectoriesProbe).self))
        #expect(requireSendable((any GitService).self))
        #expect(requireSendable((any BlobService).self))
        #expect(requireSendable((any MultiplexerAdapter).self))
        #expect(requireSendable((any WorkspacePathResolver).self))
        #expect(requireSendable((any SyntaxHighlighter).self))
        #expect(requireSendable((any Clock).self))
        #expect(requireSendable((any IDProvider).self))
        #expect(requireSendable((any UserFacingError).self))
    }

    @Test func everyValueTypeInAPortSignatureIsSendable() {
        #expect(requireSendable(TransportKind.self))
        #expect(requireSendable(TransportState.self))
        #expect(requireSendable(TransportCapabilities.self))
        #expect(requireSendable(TerminalSize.self))
        #expect(requireSendable(HostKey.self))
        #expect(requireSendable(HostKeyFingerprint.self))
        #expect(requireSendable(HostKeyVerdict.self))
        #expect(requireSendable(KnownHostStatus.self))
        #expect(requireSendable(AuthPrompt.self))
        #expect(requireSendable(AuthPromptRound.self))
        #expect(requireSendable(AuthPromptAnswer.self))
        #expect(requireSendable(SecretReference.self))
        #expect(requireSendable(Reachability.self))
        #expect(requireSendable(SessionRecord.self))
        #expect(requireSendable(WorkspaceLocation.self))
        #expect(requireSendable(WorkspaceLocation.Provenance.self))
        #expect(requireSendable(HostCapabilities.self))
        #expect(requireSendable(RecentDirectory.self) && requireSendable(AgentSource.self))
        #expect(requireSendable(RemoteBatch.self) && requireSendable(BatchResponse.self))
        #expect(requireSendable(RepositoryRef.self) && requireSendable(RepositoryStatus.self))
        #expect(requireSendable(ChangedFile.self) && requireSendable(Commit.self))
        #expect(requireSendable(FileDiff.self) && requireSendable(BlobRef.self))
        #expect(requireSendable(FetchedBlob.self) && requireSendable(MuxSnapshot.self))
        #expect(requireSendable(MultiplexerCapabilities.self))
        #expect(requireSendable(MuxKeyBindings.self))
        #expect(requireSendable(LineTokens.self) && requireSendable(TokenScope.self))
        #expect(requireSendable(LanguageID.self))
    }
}
