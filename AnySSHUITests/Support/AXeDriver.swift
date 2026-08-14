import Foundation
import XCTest

struct AXeDriver {
    let app: XCUIApplication

    init() throws {
        app = XCUIApplication()
    }

    @discardableResult
    func tap(_ identifier: String, waiting timeout: Double = 8) throws -> String {
        let element = element(identifier)
        guard element.waitForExistence(timeout: timeout) else {
            throw AXeFailure.missing(identifier)
        }
        element.tap()
        return identifier
    }

    @discardableResult
    func type(_ text: String) throws -> String {
        app.typeText(text)
        return text
    }

    @discardableResult
    func drag(from: CGPoint, to: CGPoint, duration: Double = 1.2) throws -> String {
        coordinate(from).press(forDuration: duration, thenDragTo: coordinate(to))
        return "drag"
    }

    @discardableResult
    func swipe(from: CGPoint, to: CGPoint, duration: Double = 0.4) throws -> String {
        coordinate(from).press(forDuration: duration, thenDragTo: coordinate(to))
        return "swipe"
    }

    @discardableResult
    func selectAll() throws -> String {
        let item = app.menuItems["Select All"]
        if item.waitForExistence(timeout: 2) { item.tap() }
        return "selectAll"
    }

    func describe() throws -> String {
        try elements().map { element in
            [element.identifier, element.label ?? "", element.value ?? ""]
                .filter { !$0.isEmpty }
                .joined(separator: "\t")
        }
        .joined(separator: "\n")
    }

    func elements() throws -> [AXElement] {
        app.descendants(matching: .any).allElementsBoundByIndex
            .filter { !$0.identifier.isEmpty }
            .map {
                AXElement(
                    identifier: $0.identifier,
                    label: $0.label,
                    value: $0.value as? String,
                    role: $0.elementType
                )
            }
    }

    func identifiers() throws -> [String] {
        app.descendants(matching: .any).allElementsBoundByIndex
            .map { $0.identifier }
            .filter { !$0.isEmpty }
    }

    func identifiers(startingWith prefix: String) throws -> [String] {
        try identifiers().filter { $0.hasPrefix(prefix) }
    }

    func contains(_ identifier: String) throws -> Bool {
        element(identifier).exists
    }

    @discardableResult
    func wait(for identifier: String, polls: Int = 20) throws -> Bool {
        element(identifier).waitForExistence(timeout: Double(polls) * 0.4)
    }

    @discardableResult
    func waitForAbsence(of identifier: String, polls: Int = 20) throws -> Bool {
        for _ in 0..<polls {
            if !element(identifier).exists { return true }
            usleep(400_000)
        }
        return false
    }

    func frame(of identifier: String) throws -> CGRect? {
        let element = element(identifier)
        return element.exists ? element.frame : nil
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func coordinate(_ point: CGPoint) -> XCUICoordinate {
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x, dy: point.y))
    }
}

enum AXeFailure: Error {
    case missing(String)
}

struct AXElement {
    let identifier: String
    let label: String?
    let value: String?
    let role: XCUIElement.ElementType
}
