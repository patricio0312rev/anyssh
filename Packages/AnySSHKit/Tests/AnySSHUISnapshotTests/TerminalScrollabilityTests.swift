#if canImport(UIKit)
import AnySSHCore
import TerminalEmulator
import Testing
import UIKit

@testable import AnySSHUI

@Suite @MainActor struct TerminalScrollabilityTests {
    private func hosted(rows: Int) -> SwiftTermEngine {
        let engine = SwiftTermEngine(size: TerminalSize(columns: 80, rows: 24), renderer: .coreText)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        window.rootViewController = UIViewController()
        window.rootViewController?.view.addSubview(engine.view)
        engine.view.frame = window.bounds
        window.isHidden = false
        window.layoutIfNeeded()

        for line in 0..<rows {
            engine.feed(Array("line \(line)\r\n".utf8)[...])
        }
        engine.surface.layoutTerminalNow()
        window.layoutIfNeeded()
        return engine
    }

    @Test func aScreenfulHasNothingToScroll() {
        let engine = hosted(rows: 5)
        let view = engine.view

        #expect(view.contentSize.height <= view.bounds.height + 1)
    }

    @Test func outputPastAScreenfulBecomesScrollable() {
        let engine = hosted(rows: 200)
        let view = engine.view

        #expect(view.isScrollEnabled)
        #expect(
            view.contentSize.height > view.bounds.height,
            "content \(view.contentSize.height) must exceed bounds \(view.bounds.height)"
        )
    }

    @Test func theHostedTerminalHasHeight() {
        let engine = hosted(rows: 200)

        #expect(engine.view.bounds.height > 0)
    }

    @Test func reopeningTheSessionDoesNotStackRecognisers() {
        let engine = hosted(rows: 200)
        let first = TerminalGestureBridge(view: engine.view)
        first.install()
        engine.gestureBridge = first
        let count = engine.view.gestureRecognizers?.count ?? 0

        let host = TerminalHostController(engine: engine)
        host.loadViewIfNeeded()
        host.viewDidAppear(false)

        #expect(engine.view.gestureRecognizers?.count == count)
        #expect(engine.gestureBridge === first)
    }

    @Test func theScrollViewsPanWaitsForNothing() {
        let engine = hosted(rows: 200)
        let bridge = TerminalGestureBridge(view: engine.view)
        bridge.install()

        let waitsFor =
            engine.view.panGestureRecognizer.value(
                forKey: "failureRequirements"
            ) as? [AnyObject]

        #expect(waitsFor == nil || waitsFor?.isEmpty == true)
    }
}
#endif
