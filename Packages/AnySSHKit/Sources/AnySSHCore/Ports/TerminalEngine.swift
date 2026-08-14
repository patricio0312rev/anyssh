@MainActor
public protocol TerminalEngine: AnyObject, Sendable {
    var size: TerminalSize { get }

    func setDelegate(_ delegate: any TerminalEngineDelegate)
    func feed(_ bytes: ArraySlice<UInt8>)
    func resize(to size: TerminalSize)
    func setScrollbackLimit(_ lines: Int)
}

@MainActor
public protocol TerminalEngineDelegate: AnyObject, Sendable {
    func engine(_ engine: any TerminalEngine, didChangeTitle title: String)
    func engine(_ engine: any TerminalEngine, didReportWorkingDirectory path: String)
    func engine(_ engine: any TerminalEngine, didRequestClipboardWrite text: String)
    func engineDidRequestClipboardRead(_ engine: any TerminalEngine) -> String?
    func engineDidRing(_ engine: any TerminalEngine)
    func engine(_ engine: any TerminalEngine, didProduceInput bytes: ArraySlice<UInt8>)
    func engine(_ engine: any TerminalEngine, didResizeTo size: TerminalSize)
}
