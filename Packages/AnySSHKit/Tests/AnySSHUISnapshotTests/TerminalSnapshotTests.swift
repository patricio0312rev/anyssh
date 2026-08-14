#if canImport(UIKit)
import SnapshotTesting
import Testing
import UIKit

@testable import AnySSHUI

@Suite struct TerminalSnapshotTests {
    @Test func eightyByTwentyFourFrame() {
        let engine = TerminalFixture.engine(renderer: .coreText)
        engine.activateRenderer()
        let surface = engine.surface
        surface.layoutIfNeeded()

        #expect(engine.activeRenderer == .coreText)
        assertSnapshot(
            of: surface,
            as: .image(
                precision: 0.99,
                perceptualPrecision: 0.98,
                traits: UITraitCollection(userInterfaceStyle: .dark)
            ),
            named: "frame80x24",
            testName: "Terminal"
        )
    }
}
#endif
