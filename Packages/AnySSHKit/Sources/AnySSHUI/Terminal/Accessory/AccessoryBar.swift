import AnySSHCore
import Foundation
import SwiftUI
import TerminalEmulator
import UniformTypeIdentifiers

public struct AccessoryBar: View {
    @State var model: AccessoryBarModel
    @State var draggedID: String?
    @State var reorderMode: Bool
    let scrollToID: String?
    var onOpenMultiplexer: (() -> Void)?
    var onOpenJumpTo: (() -> Void)?
    var onOpenSnippets: (() -> Void)?
    var onOpenChanges: (() -> Void)?
    var onOpenFiles: (() -> Void)?
    var onPaste: (() -> Void)?
    var isDictating = false
    var onImportFile: (() -> Void)?
    var onDictate: (() -> Void)?
    var showsKeyStrip = true

    public init(
        layout: AccessoryLayout = .defaults,
        input: TerminalInput = TerminalInput(),
        writer: (any DisplayWriter)? = nil,
        directory: URL? = nil,
        bindings: MuxKeyBindings? = nil,
        reorderMode: Bool = false,
        scrollToID: String? = nil
    ) {
        _model = State(
            wrappedValue: AccessoryBarModel(
                layout: layout,
                input: input,
                directory: directory,
                writer: writer,
                bindings: bindings
            ))
        _reorderMode = State(initialValue: reorderMode)
        self.scrollToID = scrollToID
    }

    public init(
        directory: URL,
        input: TerminalInput = TerminalInput(),
        writer: (any DisplayWriter)? = nil,
        bindings: MuxKeyBindings? = nil,
        reorderMode: Bool = false,
        scrollToID: String? = nil
    ) {
        _model = State(
            wrappedValue: AccessoryBarModel(
                directory: directory,
                input: input,
                writer: writer,
                bindings: bindings
            ))
        _reorderMode = State(initialValue: reorderMode)
        self.scrollToID = scrollToID
    }

    public init(
        model: AccessoryBarModel,
        reorderMode: Bool = false,
        scrollToID: String? = nil,
        isDictating: Bool = false,
        onDictate: (() -> Void)? = nil,
        onImportFile: (() -> Void)? = nil,
        onOpenSnippets: (() -> Void)? = nil,
        onOpenMultiplexer: (() -> Void)? = nil,
        onOpenJumpTo: (() -> Void)? = nil,
        onOpenChanges: (() -> Void)? = nil,
        onOpenFiles: (() -> Void)? = nil,
        onPaste: (() -> Void)? = nil,
        showsKeyStrip: Bool = true
    ) {
        _model = State(wrappedValue: model)
        _reorderMode = State(initialValue: reorderMode)
        self.scrollToID = scrollToID
        self.isDictating = isDictating
        self.onDictate = onDictate
        self.onImportFile = onImportFile
        self.onOpenSnippets = onOpenSnippets
        self.onOpenMultiplexer = onOpenMultiplexer
        self.onOpenJumpTo = onOpenJumpTo
        self.onOpenChanges = onOpenChanges
        self.onOpenFiles = onOpenFiles
        self.onPaste = onPaste
        self.showsKeyStrip = showsKeyStrip
    }

    public init(
        remoteStoreLocation: URL,
        input: TerminalInput = TerminalInput(),
        writer: (any DisplayWriter)? = nil,
        bindings: MuxKeyBindings? = nil,
        reorderMode: Bool = false,
        scrollToID: String? = nil,
        isDictating: Bool = false,
        onDictate: (() -> Void)? = nil,
        onImportFile: (() -> Void)? = nil,
        onOpenSnippets: (() -> Void)? = nil,
        onOpenMultiplexer: (() -> Void)? = nil,
        onOpenJumpTo: (() -> Void)? = nil,
        onOpenChanges: (() -> Void)? = nil,
        onOpenFiles: (() -> Void)? = nil,
        onPaste: (() -> Void)? = nil,
        showsKeyStrip: Bool = true
    ) {
        _model = State(
            wrappedValue: AccessoryBarModel(
                remoteStoreLocation: remoteStoreLocation,
                input: input,
                writer: writer,
                bindings: bindings
            ))
        _reorderMode = State(initialValue: reorderMode)
        self.scrollToID = scrollToID
        self.isDictating = isDictating
        self.onDictate = onDictate
        self.onImportFile = onImportFile
        self.onOpenSnippets = onOpenSnippets
        self.onOpenMultiplexer = onOpenMultiplexer
        self.onOpenJumpTo = onOpenJumpTo
        self.onOpenChanges = onOpenChanges
        self.onOpenFiles = onOpenFiles
        self.onPaste = onPaste
        self.showsKeyStrip = showsKeyStrip
    }
}
