#if canImport(UIKit)
import AnySSHCore
import Testing
import UIKit

@testable import AnySSHUI

@Suite struct TerminalHostLayoutTests {
    @Test func theCanvasIsIdentifiedAndSizedInPortraitAndLandscape() {
        let engine = TerminalFixture.engine(renderer: .coreText)
        let window = Self.window(hosting: engine, size: CGSize(width: 393, height: 852))

        #expect(engine.surface.accessibilityIdentifier == UIIdentifier.Terminal.canvas)
        #expect(engine.surface.isAccessibilityElement)
        let portrait = engine.surface.frame
        #expect(portrait.width > 0)
        #expect(portrait.height > 0)

        window.frame = CGRect(origin: .zero, size: CGSize(width: 852, height: 393))
        window.layoutIfNeeded()

        let landscape = engine.surface.frame
        #expect(landscape.width > portrait.width)
        #expect(landscape.height > 0)
        #expect(engine.size.columns > 0)
    }

    @Test func theSurfaceSurvivesRehosting() {
        let engine = TerminalFixture.engine(renderer: .coreText)
        let first = Self.window(hosting: engine, size: CGSize(width: 393, height: 852))
        let screen = engine.describeScreen()

        let second = Self.window(hosting: engine, size: CGSize(width: 393, height: 852))

        #expect(first.rootViewController !== second.rootViewController)
        #expect(engine.surface.superview === second.rootViewController?.view)
        #expect(engine.describeScreen() == screen)
    }

    private static func window(hosting engine: some TerminalSurfaceEngine, size: CGSize) -> UIWindow {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = TerminalHostController(engine: engine)
        window.isHidden = false
        window.layoutIfNeeded()
        return window
    }
}
#endif
