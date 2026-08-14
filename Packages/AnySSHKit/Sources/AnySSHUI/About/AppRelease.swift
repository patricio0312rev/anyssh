import Foundation

public enum AppRelease {
    public static var version: String { string(for: "CFBundleShortVersionString") ?? "0" }
    public static var build: String { string(for: "CFBundleVersion") ?? "0" }

    private static func string(for key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
