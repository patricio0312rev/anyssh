#if canImport(UIKit)
import UIKit

public typealias TerminalPlatformView = UIView
public typealias TerminalPlatformFont = UIFont
public typealias TerminalPlatformColor = UIColor
#else
import AppKit

public typealias TerminalPlatformView = NSView
public typealias TerminalPlatformFont = NSFont
public typealias TerminalPlatformColor = NSColor
#endif

extension TerminalPlatformView {
    func setTerminalIdentifier(_ identifier: String) {
        #if canImport(UIKit)
        accessibilityIdentifier = identifier
        isAccessibilityElement = true
        #else
        setAccessibilityIdentifier(identifier)
        #endif
    }

    func setTerminalAccessibilityLabel(_ label: String) {
        #if canImport(UIKit)
        accessibilityLabel = label
        #else
        setAccessibilityLabel(label)
        #endif
    }

    func layoutTerminalNow() {
        #if canImport(UIKit)
        setNeedsLayout()
        layoutIfNeeded()
        #else
        layoutSubtreeIfNeeded()
        #endif
    }
}
