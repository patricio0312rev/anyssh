import AnySSHCore
import Foundation

public struct SessionRestoreSnapshot: Equatable, Sendable {
    public let records: [SessionRecord]
    public let transcripts: [SessionID: [String]]
    public let activeSessionID: SessionID?

    public init(
        records: [SessionRecord],
        transcripts: [SessionID: [String]],
        activeSessionID: SessionID?
    ) {
        self.records = records
        self.transcripts = transcripts
        self.activeSessionID = activeSessionID
    }
}
