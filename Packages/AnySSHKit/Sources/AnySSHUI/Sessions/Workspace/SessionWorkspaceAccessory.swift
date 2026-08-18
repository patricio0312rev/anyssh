#if canImport(UIKit)
import SwiftUI

extension SessionWorkspaceView {
    var showsAccessoryBar: Bool {
        (keyboard.isVisible || pinsAccessoryBar)
            && canShowTerminalChrome
    }

    var showsCompactActions: Bool {
        isPad && !showsAccessoryBar && canShowTerminalChrome
    }

    var canShowTerminalChrome: Bool {
        model.activeSessionID != nil
            && !isSwitcherPresented
            && !isPalettePresented
            && presentedBrowser == nil
    }

    @ViewBuilder
    var accessoryBar: some View {
        terminalAccessory(showsKeyStrip: true)
    }

    @ViewBuilder
    var compactAccessory: some View {
        terminalAccessory(showsKeyStrip: false)
            .accessibilityIdentifier(UIIdentifier.Terminal.Accessory.compact)
            .padding(.trailing, Theme.Space.screenMargin)
            .padding(.bottom, Theme.Space.screenMargin)
    }

    @ViewBuilder
    func terminalAccessory(showsKeyStrip: Bool) -> some View {
        if let id = model.activeSessionID, let bar = model.barModels[id] {
            AccessoryBar(
                model: bar,
                isDictating: dictation.isListening,
                onDictate: toggleDictation,
                onImportFile: { isImportingFile = true },
                onOpenSnippets: { isSnippetsPresented = true },
                onOpenMultiplexer: model.showsMultiplexer ? { isMultiplexerPresented = true } : nil,
                onOpenJumpTo: model.showsMultiplexer ? { isJumpToPresented = true } : nil,
                onOpenChanges: { presentedBrowser = .changes },
                onOpenFiles: { presentedBrowser = .files },
                showsKeyStrip: showsKeyStrip
            )
            .id(id)
        }
    }
}
#endif
