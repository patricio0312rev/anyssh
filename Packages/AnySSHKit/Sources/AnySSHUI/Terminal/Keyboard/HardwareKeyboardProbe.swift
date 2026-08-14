#if canImport(UIKit)
@preconcurrency import UIKit

@MainActor
public enum HardwareKeyboardProbe {
    public static let shortcutLogID = "terminal.shortcut.log"
    public static let transportBytesID = "terminal.transport.bytes"

    public static func install(on host: UIView, session: () -> HardwareKeyboardSession) -> (
        shortcutLog: UILabel,
        transportBytes: UILabel
    ) {
        let shortcut = makeLabel(id: shortcutLogID)
        let transport = makeLabel(id: transportBytesID)
        host.addSubview(shortcut)
        host.addSubview(transport)
        refresh(shortcutLog: shortcut, transportBytes: transport, session: session())
        return (shortcut, transport)
    }

    public static func refresh(
        shortcutLog: UILabel,
        transportBytes: UILabel,
        session: HardwareKeyboardSession
    ) {
        shortcutLog.accessibilityValue = session.shortcutLog.map(\.label).joined(separator: ",")
        shortcutLog.accessibilityLabel = shortcutLog.accessibilityValue
        let bytes = session.transportBytes
        let rendered =
            bytes.isEmpty
            ? "[]"
            : "[" + bytes.map { String(format: "0x%02x", $0) }.joined(separator: ", ") + "]"
        transportBytes.accessibilityValue = rendered
        transportBytes.accessibilityLabel = rendered
    }

    private static func makeLabel(id: String) -> UILabel {
        let label = UILabel()
        label.isAccessibilityElement = true
        label.accessibilityIdentifier = id
        label.alpha = 0.01
        label.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        label.text = " "
        return label
    }
}
#endif
