import XCTest

extension XCUIElement {
    func element(withIdentifier identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
