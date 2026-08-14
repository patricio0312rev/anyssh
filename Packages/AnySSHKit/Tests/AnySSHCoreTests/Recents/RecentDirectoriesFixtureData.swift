import Fixtures
import Foundation

enum RecentDirectoriesFixtureData {
    static func bytes(_ name: String) throws -> Data {
        try Data(contentsOf: FixtureBundle.url("recentdirs/\(name)"))
    }

    static func text(_ name: String) throws -> String {
        String(decoding: try bytes(name), as: UTF8.self)
    }
}
