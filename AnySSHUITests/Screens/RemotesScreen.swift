import AnySSHUI
import XCTest

@MainActor
struct RemotesScreen {
    let app: XCUIApplication

    var list: XCUIElement {
        app.element(withIdentifier: UIIdentifier.Remote.list)
    }

    var emptyState: XCUIElement {
        app.element(withIdentifier: UIIdentifier.Remote.empty)
    }

    func row(_ id: String) -> XCUIElement {
        app.element(withIdentifier: UIIdentifier.Remote.row(id))
    }
}

extension AXeDriver {
    static let rowPrefix = "remote.row."
    static let rowAccessorySuffixes = [".delete", ".edit", ".reachability"]

    func remoteRows() throws -> [String] {
        try identifiers(startingWith: Self.rowPrefix)
            .filter { identifier in
                !Self.rowAccessorySuffixes.contains { identifier.hasSuffix($0) }
            }
    }
}
