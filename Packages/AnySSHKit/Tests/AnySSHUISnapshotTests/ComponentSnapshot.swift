#if canImport(UIKit)
import SnapshotTesting
import SwiftUI
import UIKit

@testable import AnySSHUI

enum ComponentSnapshot {
    static let width: CGFloat = 390

    @MainActor
    static func assert(
        _ view: some View,
        named name: String,
        height: CGFloat,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: ThemedRoot { view },
            as: .image(
                precision: 0.99,
                perceptualPrecision: 0.98,
                layout: .fixed(width: width, height: height),
                traits: UITraitCollection(userInterfaceStyle: .dark)
            ),
            named: name,
            fileID: fileID,
            file: file,
            testName: testName,
            line: line,
            column: column
        )
    }
}
#endif
