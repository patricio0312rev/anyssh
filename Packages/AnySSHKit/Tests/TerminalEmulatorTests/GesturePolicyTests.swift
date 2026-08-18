import Testing

@testable import TerminalEmulator

struct GesturePolicyTests {
    @Test(arguments: GestureModeCase.cases)
    func allModeCombinationsUseTheModePolicy(testCase: GestureModeCase) {
        let mode = TerminalGestureMode(
            alternateScreen: testCase.alternateScreen,
            mouseReporting: testCase.mouseReporting,
            touchMode: testCase.touchMode,
            shiftHeld: testCase.shiftHeld
        )

        #expect(TerminalGesturePolicy.route(for: mode) == testCase.expected)
    }

    @Test
    func aStationaryRemoteAppDragIsAClick() {
        #expect(
            TerminalGesturePolicy.shouldReportClick(route: .remoteApp, didTravel: false)
        )
        #expect(
            !TerminalGesturePolicy.shouldReportClick(route: .remoteApp, didTravel: true)
        )
        for route in [TerminalGestureRoute.scrollback, .remoteKeys, .selection] {
            #expect(!TerminalGesturePolicy.shouldReportClick(route: route, didTravel: false))
        }
    }

    @Test
    func ourPanBeginsOnEveryRoute() {
        for route in [TerminalGestureRoute.scrollback, .remoteApp, .remoteKeys, .selection] {
            #expect(TerminalGesturePolicy.dragShouldBegin(route: route, selectionActive: false))
            #expect(TerminalGesturePolicy.dragShouldBegin(route: route, selectionActive: true))
        }
    }

    @Test
    func twoFingersAreRequiredForSessionSwitching() {
        #expect(!SessionSwitchGesturePolicy.accepts(touchCount: 1))
        #expect(SessionSwitchGesturePolicy.accepts(touchCount: 2))
        #expect(!SessionSwitchGesturePolicy.accepts(touchCount: 3))
    }

    @Test
    func alternateScreenWithoutMouseReportingSendsCursorKeys() {
        var harness = GestureHarness()
        harness.drag(
            mode: TerminalGestureMode(
                alternateScreen: true,
                mouseReporting: false,
                touchMode: false,
                shiftHeld: false
            ))

        #expect(harness.transportWriteLog == [27, 91, 65])
        #expect(harness.scrollOffset == 0)
    }

    @Test
    func touchModeKeepsTheAlternateScreenLocal() {
        var harness = GestureHarness()
        harness.drag(
            mode: TerminalGestureMode(
                alternateScreen: true,
                mouseReporting: false,
                touchMode: true,
                shiftHeld: false
            ))

        #expect(harness.transportWriteLog.isEmpty)
        #expect(harness.scrollOffset == 1)
    }

    @Test
    func alternateScreenWithMouseReportingSendsTheReport() {
        var harness = GestureHarness()
        harness.drag(
            mode: TerminalGestureMode(
                alternateScreen: true,
                mouseReporting: true,
                touchMode: false,
                shiftHeld: false
            ))

        #expect(harness.transportWriteLog == Array("\u{1B}[<0;5;8M".utf8))
        #expect(harness.scrollOffset == 0)
    }

    @Test
    func scrollbackDragMovesOffsetAndWritesNoMouseBytes() {
        var harness = GestureHarness()
        harness.drag(
            mode: TerminalGestureMode(
                alternateScreen: false,
                mouseReporting: false,
                touchMode: false,
                shiftHeld: false
            ))

        #expect(harness.transportWriteLog.isEmpty)
        #expect(harness.scrollOffset == 1)
    }

    @Test
    func touchModeForcesScrollbackWhileMouseReportingIsOn() {
        let mode = TerminalGestureMode(
            alternateScreen: false,
            mouseReporting: true,
            touchMode: true,
            shiftHeld: false
        )
        #expect(TerminalGesturePolicy.route(for: mode) == .scrollback)
    }

    @Test
    func shiftBypassesMouseReportingForLocalSelection() {
        let mode = TerminalGestureMode(
            alternateScreen: true,
            mouseReporting: true,
            touchMode: false,
            shiftHeld: true
        )
        #expect(TerminalGesturePolicy.route(for: mode) == .selection)
    }

    @Test
    func theShellStillScrollsLocally() {
        let mode = TerminalGestureMode(
            alternateScreen: false,
            mouseReporting: false,
            touchMode: false,
            shiftHeld: false
        )
        #expect(TerminalGesturePolicy.route(for: mode) == .scrollback)
    }

    @Test
    func selectionContextRecognizesLinksAndPaths() {
        #expect(TerminalSelectionContext.detect(in: "https://example.com/a") == .url("https://example.com/a"))
        #expect(TerminalSelectionContext.detect(in: "/var/log/system.log") == .path("/var/log/system.log"))
        #expect(TerminalSelectionContext.detect(in: "plain text") == .none)
    }
}
