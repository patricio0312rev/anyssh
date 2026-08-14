import AnySSHCore
import Foundation
import SwiftTerm

extension SwiftTermEngine: @MainActor TerminalViewDelegate {
    public func setTerminalTitle(source: TerminalView, title: String) {
        engineDelegate?.engine(self, didChangeTitle: title)
    }

    public func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        guard let directory, let path = TerminalWorkingDirectory.path(from: directory) else { return }
        engineDelegate?.engine(self, didReportWorkingDirectory: path)
    }

    public func clipboardCopy(source: TerminalView, content: Data) {
        engineDelegate?.engine(self, didRequestClipboardWrite: String(decoding: content, as: UTF8.self))
    }

    public func clipboardRead(source: TerminalView) -> Data? {
        guard let text = engineDelegate?.engineDidRequestClipboardRead(self) else { return nil }
        return Data(text.utf8)
    }

    public func bell(source: TerminalView) {
        engineDelegate?.engineDidRing(self)
    }

    public func send(source: TerminalView, data: ArraySlice<UInt8>) {
        let transformed = transformInput?(data) ?? Array(data)
        engineDelegate?.engine(self, didProduceInput: transformed[...])
    }

    public func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        let size = TerminalSize(
            columns: newCols,
            rows: newRows,
            pixelWidth: Int(source.bounds.width),
            pixelHeight: Int(source.bounds.height)
        )
        engineDelegate?.engine(self, didResizeTo: size)
    }

    public func scrolled(source: TerminalView, position: Double) {}

    public func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {}

    public func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}
}
