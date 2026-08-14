#if canImport(UIKit)
import Testing
import UIKit

@testable import AnySSHUI

@Suite struct TerminalGeometryTests {
    @Test func iPhone17ProLandscapeKeepsColumnsInsideTheSafeArea() {
        let geometry = IPhone17ProLandscape.geometry
        let frame = geometry.surfaceFrame
        let insets = geometry.safeAreaInsets
        let width = geometry.bounds.width

        #expect(frame.minX >= insets.left)
        #expect(frame.maxX <= width - insets.right)
        #expect(geometry.respectsHorizontalSafeArea())
        #expect(frame.origin == CGPoint(x: insets.left, y: insets.top))
        #expect(frame.width == width - insets.left - insets.right)

        let host = UIView(frame: geometry.bounds)
        host.backgroundColor = .black
        let surface = UIView(frame: frame)
        surface.backgroundColor = MonokaiProPalette.windowBackground
        host.addSubview(surface)
        host.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(bounds: host.bounds)
        let image = renderer.image { _ in
            host.drawHierarchy(in: host.bounds, afterScreenUpdates: true)
        }
        Attachment.record(image, named: "iPhone17Pro-landscape-safe-area", as: .png)
    }

    @Test func safeAreaLayoutCalculatorMatchesTheGeometryFrame() {
        let geometry = IPhone17ProLandscape.geometry
        let frame = TerminalSafeAreaLayout.frame(
            for: geometry.bounds,
            safeAreaInsets: geometry.safeAreaInsets
        )

        #expect(frame == geometry.surfaceFrame)
        #expect(frame.minX >= geometry.safeAreaInsets.left)
        #expect(frame.maxX <= geometry.bounds.width - geometry.safeAreaInsets.right)
    }

    @Test func keyboardOverlapRaisesTheBottomEdge() {
        let geometry = TerminalGeometry(
            bounds: CGRect(x: 0, y: 0, width: 400, height: 800),
            safeAreaInsets: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
            keyboardOverlap: 300
        )

        #expect(geometry.surfaceFrame.maxY == 500)
        #expect(geometry.surfaceFrame.minX == 0)
    }

    @Test @MainActor func pinningASurfaceRespectsInjectedSafeAreaInsets() {
        let geometry = IPhone17ProLandscape.geometry
        let window = UIWindow(frame: geometry.bounds)
        let host = UIViewController()
        host.additionalSafeAreaInsets = geometry.safeAreaInsets
        window.rootViewController = host
        window.isHidden = false

        let surface = UIView()
        surface.backgroundColor = MonokaiProPalette.windowBackground
        TerminalSafeAreaLayout.pin(surface, in: host.view, keyboardTop: host.view.bottomAnchor)
        window.layoutIfNeeded()

        let frame = surface.frame
        #expect(frame.minX >= host.view.safeAreaInsets.left - 0.5)
        #expect(frame.maxX <= geometry.bounds.width - host.view.safeAreaInsets.right + 0.5)
    }
}
#endif
