import TerminalEmulator
import Testing

struct GestureModeCase: CustomTestStringConvertible, Sendable {
    let alternateScreen: Bool
    let mouseReporting: Bool
    let touchMode: Bool
    let shiftHeld: Bool
    let expected: TerminalGestureRoute

    var testDescription: String {
        "alternate=\(alternateScreen), mouse=\(mouseReporting), touch=\(touchMode), shift=\(shiftHeld) -> \(expected.rawValue)"
    }

    static let cases: [GestureModeCase] =
        ([
            (false, false, false, false, .scrollback),
            (false, false, false, true, .selection),
            (false, false, true, false, .scrollback),
            (false, false, true, true, .selection),
            (false, true, false, false, .remoteApp),
            (false, true, false, true, .selection),
            (false, true, true, false, .scrollback),
            (false, true, true, true, .selection),
            (true, false, false, false, .remoteKeys),
            (true, false, false, true, .selection),
            (true, false, true, false, .scrollback),
            (true, false, true, true, .selection),
            (true, true, false, false, .remoteApp),
            (true, true, false, true, .selection),
            (true, true, true, false, .scrollback),
            (true, true, true, true, .selection),
        ] as [(Bool, Bool, Bool, Bool, TerminalGestureRoute)])
        .map { values in
            GestureModeCase(
                alternateScreen: values.0,
                mouseReporting: values.1,
                touchMode: values.2,
                shiftHeld: values.3,
                expected: values.4
            )
        }
}

struct GestureHarness {
    var transportWriteLog: [UInt8] = []
    var scrollOffset = 0

    mutating func drag(mode: TerminalGestureMode) {
        switch TerminalGesturePolicy.route(for: mode) {
        case .remoteApp:
            transportWriteLog +=
                TerminalMouseReport(
                    button: .primary,
                    column: 4,
                    row: 7,
                    pressed: true
                ).sgrBytes
        case .remoteKeys:
            var input = TerminalInput()
            transportWriteLog += input.send(.up)
        case .scrollback:
            scrollOffset += 1
        case .selection:
            break
        }
    }
}
