import AnySSHCore
import Foundation

public enum StartDirectoryPolicy {
    public static func path(remembered: String?, configured: String?) -> String? {
        for candidate in [configured, remembered] {
            let trimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let trimmed, !trimmed.isEmpty, trimmed != "~" { return trimmed }
        }
        return nil
    }
}
