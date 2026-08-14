import AnySSHCore

public protocol TerminalSurfaceEngine: TerminalEngine {
    var surface: TerminalPlatformView { get }

    var preferredRenderer: TerminalRenderer { get }
    var activeRenderer: TerminalRenderer { get }

    var bufferingMode: TerminalBufferingMode { get set }

    var wantsKeyboard: Bool { get set }

    @discardableResult
    func activateRenderer() -> TerminalRenderer

    var transformInput: ((ArraySlice<UInt8>) -> [UInt8])? { get set }

    func describeScreen() -> String

    func emitInput(_ bytes: ArraySlice<UInt8>)

    func registerOSCHandler(code: Int, handler: @escaping (ArraySlice<UInt8>) -> Void)
}
