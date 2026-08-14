import Foundation

public struct CommitID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct Commit: Identifiable, Hashable, Sendable {
    public let id: CommitID
    public let parents: [CommitID]
    public let authorName: String
    public let authorEmail: String
    public let authoredAt: Date
    public let subject: String
    public let body: String
    public let references: [String]

    public init(
        id: CommitID,
        parents: [CommitID],
        authorName: String,
        authorEmail: String,
        authoredAt: Date,
        subject: String,
        body: String,
        references: [String] = []
    ) {
        self.id = id
        self.parents = parents
        self.authorName = authorName
        self.authorEmail = authorEmail
        self.authoredAt = authoredAt
        self.subject = subject
        self.body = body
        self.references = references
    }
}
