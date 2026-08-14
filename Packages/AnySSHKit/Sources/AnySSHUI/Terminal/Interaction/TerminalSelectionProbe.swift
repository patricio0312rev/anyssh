#if canImport(UIKit)
import UIKit

@MainActor
public final class TerminalSelectionProbe {
    public private(set) var selectionEndColumn = 0
    public private(set) var selectionEndRow = 0
    public private(set) var scrollOffsetY: CGFloat = 0
    public private(set) var lastRoute = "scrollback"
    public private(set) var switcherOpened = false

    private weak var host: UIView?
    private let endLabel = UILabel()
    private let scrollLabel = UILabel()
    private let routeLabel = UILabel()
    private let switcherLabel = UILabel()

    public init() {}

    public func install(on host: UIView) {
        self.host = host
        configure(endLabel, id: UIIdentifier.Terminal.Gestures.selectionEnd)
        configure(scrollLabel, id: UIIdentifier.Terminal.Gestures.scrollOffset)
        configure(routeLabel, id: UIIdentifier.Terminal.Gestures.route)
        configure(switcherLabel, id: UIIdentifier.Terminal.Gestures.sessionSwitcher)
        publish()
    }

    public func update(
        selectionEndColumn: Int,
        selectionEndRow: Int,
        scrollOffsetY: CGFloat,
        route: String
    ) {
        self.selectionEndColumn = selectionEndColumn
        self.selectionEndRow = selectionEndRow
        self.scrollOffsetY = scrollOffsetY
        lastRoute = route
        publish()
    }

    public func noteSessionSwitch() {
        switcherOpened = true
        switcherLabel.accessibilityValue = "open"
        switcherLabel.isAccessibilityElement = true
    }

    private func configure(_ label: UILabel, id: String) {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isAccessibilityElement = true
        label.accessibilityIdentifier = id
        label.alpha = 0.01
        label.font = .systemFont(ofSize: 1)
        host?.addSubview(label)
        if let host {
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: host.leadingAnchor),
                label.topAnchor.constraint(equalTo: host.topAnchor),
                label.widthAnchor.constraint(equalToConstant: 1),
                label.heightAnchor.constraint(equalToConstant: 1),
            ])
        }
    }

    private func publish() {
        endLabel.accessibilityValue = "\(selectionEndColumn),\(selectionEndRow)"
        scrollLabel.accessibilityValue = String(format: "%.1f", scrollOffsetY)
        routeLabel.accessibilityValue = lastRoute
    }
}
#endif
