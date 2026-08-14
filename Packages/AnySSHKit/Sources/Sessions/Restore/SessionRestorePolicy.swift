import AnySSHCore
import Foundation

public enum SessionRestorePolicy {
    public static let schemaVersion = 1
    public static let fileName = "session-restore.json"

    public static let persistedTailLines = 1_000
}
