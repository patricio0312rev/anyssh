import Fixtures
import Foundation

enum MuxFixtureData {
    static func text(_ name: String) throws -> String {
        String(decoding: try bytes(name), as: UTF8.self)
    }

    static func bytes(_ name: String) throws -> Data {
        try Data(contentsOf: FixtureBundle.url("mux/\(name)"))
    }
}
