import AnySSHCore
import SwiftTerm

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

public final class SwiftTermEngine: TerminalSurfaceEngine {
    let view: TerminalView
    weak var engineDelegate: (any TerminalEngineDelegate)?

    public var transformInput: ((ArraySlice<UInt8>) -> [UInt8])?

    public var wantsKeyboard = false

    public var gestureBridge: AnyObject?

    public let preferredRenderer: TerminalRenderer
    public private(set) var activeRenderer: TerminalRenderer = .coreText

    public private(set) var rendererFallbackReason: String?

    public var bufferingMode: TerminalBufferingMode {
        didSet { apply(bufferingMode) }
    }

    public var surface: TerminalPlatformView { view }

    public var size: TerminalSize {
        let terminal = view.getTerminal()
        return TerminalSize(
            columns: terminal.cols,
            rows: terminal.rows,
            pixelWidth: Int(view.bounds.width),
            pixelHeight: Int(view.bounds.height)
        )
    }

    public var modes: TerminalModeSnapshot {
        let terminal = view.getTerminal()
        return TerminalModeSnapshot(
            applicationCursor: terminal.applicationCursor,
            alternateBuffer: terminal.isCurrentBufferAlternate,
            mouseReporting: terminal.mouseMode != .off
        )
    }

    public init(
        size: TerminalSize = .standard,
        renderer: TerminalRenderer = .metal,
        bufferingMode: TerminalBufferingMode = .perRowPersistent,
        scrollbackLines: Int = 5000,
        fonts: TerminalFontSet = TerminalFontSet()
    ) {
        var options = TerminalOptions.default
        options.cols = size.columns
        options.rows = size.rows
        options.scrollback = scrollbackLines
        options.cursorStyle = .steadyBlock
        preferredRenderer = renderer
        self.bufferingMode = bufferingMode
        view = TerminalView(frame: .zero, font: fonts.normal, options: options)
        #if canImport(UIKit)
        view.setFonts(
            normal: fonts.normal,
            bold: fonts.bold,
            italic: fonts.italic,
            boldItalic: fonts.boldItalic
        )
        #endif
        view.terminalDelegate = self
        view.setTerminalIdentifier(UIIdentifier.Terminal.canvas)
        view.setTerminalAccessibilityLabel("Terminal")
        #if canImport(UIKit)
        view.inputAccessoryView = nil
        #endif
        MonokaiProPalette.apply(to: view)
        apply(bufferingMode)
        view.frame = view.getOptimalFrameSize()
    }

    public func setDelegate(_ delegate: any TerminalEngineDelegate) {
        engineDelegate = delegate
    }

    public func registerOSCHandler(code: Int, handler: @escaping (ArraySlice<UInt8>) -> Void) {
        view.getTerminal().registerOscHandler(code: code, handler: handler)
    }

    public func emitInput(_ bytes: ArraySlice<UInt8>) {
        engineDelegate?.engine(self, didProduceInput: bytes)
    }

    public func feed(_ bytes: ArraySlice<UInt8>) {
        view.feed(byteArray: bytes)
        publishScreenToAccessibility()
    }

    private func publishScreenToAccessibility() {
        #if canImport(UIKit)
        guard UIAccessibility.isVoiceOverRunning else { return }
        view.accessibilityValue = describeScreen()
        #endif
    }

    public func resize(to size: TerminalSize) {
        let terminal = view.getTerminal()
        guard terminal.cols != size.columns || terminal.rows != size.rows else { return }
        view.frame = CGRect(origin: view.frame.origin, size: surfaceSize(for: size))
        view.layoutTerminalNow()
    }

    public func setScrollbackLimit(_ lines: Int) {
        view.changeScrollback(max(0, lines))
    }

    @discardableResult
    public func activateRenderer() -> TerminalRenderer {
        activeRenderer = enableMetal(preferredRenderer == .metal)
        return activeRenderer
    }

    public func describeScreen() -> String {
        String(decoding: view.getTerminal().getBufferAsData(), as: UTF8.self)
    }

    private func enableMetal(_ enabled: Bool) -> TerminalRenderer {
        #if canImport(MetalKit)
        do {
            try view.setUseMetal(enabled)
        } catch {
            rendererFallbackReason = String(describing: error)
            return .coreText
        }
        rendererFallbackReason = nil
        return view.isUsingMetalRenderer ? .metal : .coreText
        #else
        rendererFallbackReason = "MetalKit is unavailable on this platform"
        return .coreText
        #endif
    }

    private func apply(_ mode: TerminalBufferingMode) {
        #if canImport(MetalKit)
        view.metalBufferingMode = mode == .perRowPersistent ? .perRowPersistent : .perFrameAggregated
        #endif
    }

    private func surfaceSize(for size: TerminalSize) -> CGSize {
        let terminal = view.getTerminal()
        let optimal = view.getOptimalFrameSize().size
        let caret = view.caretFrame.size
        let cellWidth = caret.width > 0 ? caret.width : optimal.width / CGFloat(terminal.cols)
        let cellHeight = caret.height > 0 ? caret.height : optimal.height / CGFloat(terminal.rows)
        let reserved = max(0, optimal.width - cellWidth * CGFloat(terminal.cols))
        return CGSize(
            width: cellWidth * (CGFloat(size.columns) + 0.5) + reserved,
            height: cellHeight * (CGFloat(size.rows) + 0.5)
        )
    }
}
