import Foundation

public enum SessionRestoreError: Error, Equatable {
    case unreadable
    case unsupportedSchemaVersion(Int)
}
