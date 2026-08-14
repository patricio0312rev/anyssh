import TerminalEmulator

#if canImport(UIKit)
@preconcurrency import UIKit
#endif

public struct AppKeyEquivalent: Hashable, Sendable {
    public enum Modifier: Hashable, Sendable {
        case command
        case control
        case shift
        case alt
    }

    public let key: HardwareKeyCode
    public let modifiers: Set<Modifier>

    public init(key: HardwareKeyCode, modifiers: Set<Modifier> = [.command]) {
        self.key = key
        self.modifiers = modifiers
    }

    public func matches(_ event: AppShortcutEvent) -> Bool {
        key == event.key
            && modifiers.contains(.command) == event.command
            && modifiers.contains(.control) == event.control
            && modifiers.contains(.shift) == event.shift
            && modifiers.contains(.alt) == event.alt
    }

    public var label: String {
        var parts = [String]()
        if modifiers.contains(.control) { parts.append("Ctrl") }
        if modifiers.contains(.alt) { parts.append("Alt") }
        if modifiers.contains(.shift) { parts.append("Shift") }
        if modifiers.contains(.command) { parts.append("Cmd") }
        let name = key.terminalKey?.name ?? String(key.rawValue)
        parts.append(name.count == 1 ? name.uppercased() : name)
        return parts.joined(separator: "+")
    }

    public var input: String? {
        key.terminalKey?.name
    }

    #if canImport(UIKit)
    public var uiModifierFlags: UIKeyModifierFlags {
        var flags = UIKeyModifierFlags()
        if modifiers.contains(.command) { flags.insert(.command) }
        if modifiers.contains(.control) { flags.insert(.control) }
        if modifiers.contains(.shift) { flags.insert(.shift) }
        if modifiers.contains(.alt) { flags.insert(.alternate) }
        return flags
    }
    #endif
}
