import Foundation

public enum AppDirectories {
    public static let containerName = "AnySSH"

    public static var support: URL {
        URL.applicationSupportDirectory.appending(path: containerName)
    }
}
