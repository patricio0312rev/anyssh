import XCTest

extension XCUIApplication {
    static func launched(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-UITestMode", "YES"]
        app.launchEnvironment["ANYSSH_SCENARIO"] = scenario
        app.launch()
        return app
    }
}
