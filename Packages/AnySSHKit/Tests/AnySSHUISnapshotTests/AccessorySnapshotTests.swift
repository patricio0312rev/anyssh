#if canImport(UIKit)
import AnySSHCore
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

@testable import AnySSHUI

@Suite @MainActor struct AccessorySnapshotTests {
    @Test func defaultBar() {
        assert(AccessoryBar(), named: "default")
    }

    @Test func overflowScrolled() {
        let layout = AccessoryLayout(
            keys: (0..<30).map { index in
                AccessoryLayout.Key(
                    id: "terminal.accessory.key.overflow-\(index)",
                    label: "K\(index)",
                    tap: .key("k")
                )
            })
        assert(
            AccessoryBar(layout: layout, scrollToID: "terminal.accessory.key.overflow-29"),
            named: "overflow-scrolled"
        )
    }

    @Test func reorderMode() {
        assert(AccessoryBar(reorderMode: true), named: "reorder")
    }

    private func assert(_ view: some View, named: String, line: UInt = #line) {
        assertSnapshot(
            of: view,
            as: .image(
                precision: 0.99,
                perceptualPrecision: 0.98,
                layout: .fixed(width: 390, height: 92),
                traits: UITraitCollection(userInterfaceStyle: .dark)
            ),
            named: named,
            testName: "Accessory",
            line: line
        )
    }
}
#endif
