#if canImport(UIKit)
@preconcurrency import UIKit

@MainActor
public enum TerminalSafeAreaLayout {
    @discardableResult
    public static func pin(
        _ surface: UIView,
        in host: UIView,
        keyboardTop: NSLayoutYAxisAnchor? = nil
    ) -> [NSLayoutConstraint] {
        surface.translatesAutoresizingMaskIntoConstraints = false
        if surface.superview !== host {
            surface.removeFromSuperview()
            host.addSubview(surface)
        }
        let guides = host.safeAreaLayoutGuide
        let bottomAnchor = keyboardTop ?? host.keyboardLayoutGuide.topAnchor
        let constraints = [
            surface.topAnchor.constraint(equalTo: guides.topAnchor),
            surface.leadingAnchor.constraint(equalTo: guides.leadingAnchor),
            surface.trailingAnchor.constraint(equalTo: guides.trailingAnchor),
            surface.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    public static func frame(
        for hostBounds: CGRect,
        safeAreaInsets: UIEdgeInsets,
        keyboardOverlap: CGFloat = 0
    ) -> CGRect {
        TerminalGeometry(
            bounds: hostBounds,
            safeAreaInsets: safeAreaInsets,
            keyboardOverlap: keyboardOverlap
        ).surfaceFrame
    }
}
#endif
