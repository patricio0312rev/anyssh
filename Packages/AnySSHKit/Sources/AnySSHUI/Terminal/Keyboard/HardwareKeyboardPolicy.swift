import TerminalEmulator

public enum HardwareKeyRoute: Hashable, Sendable {
    case appShortcut
    case transport
    case ignore
}

public struct HardwareKeyboardPolicy: Hashable, Sendable {
    public var optionAsMetaKey: Bool
    public var kittyKeyboardActive: Bool

    public init(optionAsMetaKey: Bool = true, kittyKeyboardActive: Bool = false) {
        self.optionAsMetaKey = optionAsMetaKey
        self.kittyKeyboardActive = kittyKeyboardActive
    }

    public func route(key: HardwareKeyCode, modifiers: KeyModifiers, commandHeld: Bool) -> HardwareKeyRoute {
        guard !key.isModifierOnly, key.terminalKey != nil else { return .ignore }
        if commandHeld {
            return kittyKeyboardActive ? .transport : .appShortcut
        }
        return .transport
    }

    public func wireModifiers(control: Bool, alt: Bool, shift: Bool) -> KeyModifiers {
        var modifiers = KeyModifiers()
        if control { modifiers.insert(.control) }
        if shift { modifiers.insert(.shift) }
        if alt, optionAsMetaKey { modifiers.insert(.alt) }
        return modifiers
    }
}

public struct AppShortcutEvent: Hashable, Sendable {
    public let key: HardwareKeyCode
    public let command: Bool
    public let shift: Bool
    public let control: Bool
    public let alt: Bool

    public init(
        key: HardwareKeyCode,
        command: Bool = true,
        shift: Bool = false,
        control: Bool = false,
        alt: Bool = false
    ) {
        self.key = key
        self.command = command
        self.shift = shift
        self.control = control
        self.alt = alt
    }

    public var label: String {
        var parts = [String]()
        if control { parts.append("Ctrl") }
        if alt { parts.append("Alt") }
        if shift { parts.append("Shift") }
        if command { parts.append("Cmd") }
        let name = key.terminalKey?.name ?? String(key.rawValue)
        parts.append(name.count == 1 ? name.uppercased() : name)
        return parts.joined(separator: "+")
    }
}
