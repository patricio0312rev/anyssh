import Foundation
import XCTest

enum SimulatorURL {
    static func open(_ string: String) throws {
        guard let url = URL(string: string) else {
            throw XCTSkip("\(string) is not a URL.")
        }
        XCUIDevice.shared.system.open(url)
    }
}
