#if canImport(UIKit)
import Foundation
import Testing
import UIKit

@testable import AnySSHUI

@Suite @MainActor struct TerminalLayoutPinchTests {
    @Test func aPinchWithTwentyIntermediateScalesSendsOneTransportResize() {
        let name = "terminal.layout.pinch.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: name)!
        defer { suite.removePersistentDomain(forName: name) }
        suite.set(13.0, forKey: TerminalFontSizeStore.defaultsKey)
        let store = TerminalFontSizeStore(defaults: suite)
        var committed = [CGFloat]()
        let controller = TerminalPinchFontController(store: store) { size in
            committed.append(size)
        }

        controller.apply(scale: 1.0, state: .began)
        for step in 1...20 {
            let scale = 1.0 + CGFloat(step) * 0.02
            controller.apply(scale: scale, state: .changed)
        }
        controller.apply(scale: 1.4, state: .ended)

        #expect(controller.intermediateScaleCount == 20)
        #expect(controller.transportResizeCount == 1)
        #expect(committed == [TerminalFontSizeStore.size(base: 13, scale: 1.4)])
        #expect(controller.committedSize == TerminalFontSizeStore.size(base: 13, scale: 1.4))
    }

    @Test func aCancelledPinchDoesNotResizeTheTransport() {
        let name = "terminal.layout.pinch.cancel.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: name)!
        defer { suite.removePersistentDomain(forName: name) }
        let store = TerminalFontSizeStore(defaults: suite)
        let controller = TerminalPinchFontController(store: store)

        controller.apply(scale: 1.0, state: .began)
        controller.apply(scale: 1.5, state: .changed)
        controller.apply(scale: 1.5, state: .cancelled)

        #expect(controller.transportResizeCount == 0)
        #expect(controller.committedSize == TerminalFontSizeStore.defaultSize)
        #expect(controller.previewSize == controller.committedSize)
    }

    @Test func theCommittedFontSizePersistsAcrossARelaunch() {
        let name = "terminal.layout.font.\(UUID().uuidString)"
        let firstDefaults = UserDefaults(suiteName: name)!
        defer { firstDefaults.removePersistentDomain(forName: name) }
        let firstStore = TerminalFontSizeStore(defaults: firstDefaults)
        let first = TerminalPinchFontController(store: firstStore)
        first.apply(scale: 1.0, state: .began)
        first.apply(scale: 1.5, state: .ended)

        let relaunchedDefaults = UserDefaults(suiteName: name)!
        let relaunched = TerminalFontSizeStore(defaults: relaunchedDefaults)
        let second = TerminalPinchFontController(store: relaunched)

        #expect(second.committedSize == first.committedSize)
        #expect(relaunched.load() == first.committedSize)
    }
}
#endif
