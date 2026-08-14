import AnySSHUI
import XCTest

enum HardwareKeyInput {
    static func send(modifiers: [UInt16], key: UInt16) throws {
        guard let input = self.input(for: key) else {
            throw XCTSkip("No typeKey input for HID code \(key).")
        }
        if !modifiers.isEmpty {
            throw XCTSkip("XCUITest does not deliver modifier flags to the app under test.")
        }
        XCUIApplication().typeKey(input, modifierFlags: flags(modifiers))
    }

    private static func flags(_ modifiers: [UInt16]) -> XCUIElement.KeyModifierFlags {
        var flags = XCUIElement.KeyModifierFlags()
        for modifier in modifiers.compactMap(HardwareKeyCode.init(rawValue:)) {
            switch modifier {
            case .leftCommand, .rightCommand: flags.insert(.command)
            case .leftControl, .rightControl: flags.insert(.control)
            case .leftAlt, .rightAlt: flags.insert(.option)
            case .leftShift, .rightShift: flags.insert(.shift)
            default: break
            }
        }
        return flags
    }

    private static func input(for key: UInt16) -> String? {
        guard let code = HardwareKeyCode(rawValue: key) else { return nil }
        if let special = specials[code] { return special }
        let name = String(describing: code)
        return name.count == 1 ? name : digits[code]
    }

    private static let specials: [HardwareKeyCode: String] = [
        .enter: XCUIKeyboardKey.enter.rawValue,
        .escape: XCUIKeyboardKey.escape.rawValue,
        .backspace: XCUIKeyboardKey.delete.rawValue,
        .tab: XCUIKeyboardKey.tab.rawValue,
        .space: " ",
        .up: XCUIKeyboardKey.upArrow.rawValue,
        .down: XCUIKeyboardKey.downArrow.rawValue,
        .left: XCUIKeyboardKey.leftArrow.rawValue,
        .right: XCUIKeyboardKey.rightArrow.rawValue,
    ]

    private static let digits: [HardwareKeyCode: String] = [
        .one: "1", .two: "2", .three: "3", .four: "4", .five: "5",
        .six: "6", .seven: "7", .eight: "8", .nine: "9", .zero: "0",
    ]
}
