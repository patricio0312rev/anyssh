import XCTest

enum PastePermission {
    private static let labels = ["Allow Paste", "Paste", "Allow"]

    static func monitor(on testCase: XCTestCase) -> NSObjectProtocol {
        testCase.addUIInterruptionMonitor(withDescription: "Paste permission") { alert in
            for label in labels {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    static func allow(timeout: TimeInterval = 6) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let app = XCUIApplication()
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for label in labels {
                for button in [
                    springboard.buttons[label],
                    springboard.alerts.buttons[label],
                    app.buttons[label],
                    app.alerts.buttons[label],
                ] where button.exists {
                    button.tap()
                    return
                }
            }
            usleep(300_000)
        }
    }
}
