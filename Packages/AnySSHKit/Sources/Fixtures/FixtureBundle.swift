import Foundation

public enum FixtureBundle {
    public static func url(_ path: String) -> URL {
        let root = Bundle.module.resourceURL ?? Bundle.module.bundleURL
        return root.appending(path: "Data", directoryHint: .isDirectory).appending(path: path)
    }
}
