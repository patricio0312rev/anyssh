import AnySSHCore
import TerminalEmulator

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public enum AppCommandBinding {
    public static func workspaceCommands(
        model: SessionWorkspaceModel,
        onNewConnection: @escaping () -> Void,
        onOpenSwitcher: @escaping () -> Void,
        onOpenPalette: @escaping () -> Void,
        onOpenChanges: @escaping () -> Void,
        onOpenJumpTo: @escaping () -> Void = {}
    ) -> [AppCommand] {
        sessionLifecycleCommands(model, onNewConnection: onNewConnection)
            + sessionCommands(model)
            + surfaceCommands(
                model,
                onOpenSwitcher: onOpenSwitcher,
                onOpenPalette: onOpenPalette,
                onOpenChanges: onOpenChanges,
                onOpenJumpTo: onOpenJumpTo
            )
    }

    private static func sessionLifecycleCommands(
        _ model: SessionWorkspaceModel,
        onNewConnection: @escaping () -> Void
    ) -> [AppCommand] {
        [
            AppCommand(
                id: "app.newConnection",
                title: "New Connection",
                keyEquivalent: AppKeyEquivalent(key: .n),
                isEnabled: { true },
                handler: onNewConnection
            ),
            AppCommand(
                id: "app.closeSession",
                title: "Close Session",
                keyEquivalent: AppKeyEquivalent(key: .w),
                isEnabled: { model.activeSessionID != nil },
                disabledReason: { model.activeSessionID == nil ? noActiveSession : nil },
                handler: {
                    guard let id = model.activeSessionID else { return }
                    Task { await model.close(id) }
                }
            ),
            AppCommand(
                id: "session.next",
                title: "Next Session",
                keyEquivalent: nil,
                isEnabled: { model.registry.count > 1 },
                disabledReason: { model.registry.count > 1 ? nil : oneSessionOpen },
                handler: { step(model, by: 1) }
            ),
            AppCommand(
                id: "session.previous",
                title: "Previous Session",
                keyEquivalent: nil,
                isEnabled: { model.registry.count > 1 },
                disabledReason: { model.registry.count > 1 ? nil : oneSessionOpen },
                handler: { step(model, by: -1) }
            ),
        ]
    }

    private static func surfaceCommands(
        _ model: SessionWorkspaceModel,
        onOpenSwitcher: @escaping () -> Void,
        onOpenPalette: @escaping () -> Void,
        onOpenChanges: @escaping () -> Void,
        onOpenJumpTo: @escaping () -> Void
    ) -> [AppCommand] {
        [
            AppCommand(
                id: "app.openSwitcher",
                title: "Open Switcher",
                keyEquivalent: AppKeyEquivalent(key: .o),
                isEnabled: { true },
                handler: onOpenSwitcher
            ),
            AppCommand(
                id: "app.openJumpTo",
                title: "Open Jump to",
                keyEquivalent: nil,
                isEnabled: { model.showsMultiplexer },
                disabledReason: { model.showsMultiplexer ? nil : noMultiplexer },
                handler: onOpenJumpTo
            ),
            AppCommand(
                id: "app.openChanges",
                title: "Open Changes",
                keyEquivalent: nil,
                isEnabled: { model.activeRecord?.workspace != nil },
                disabledReason: { model.activeRecord?.workspace == nil ? noWorkspace : nil },
                handler: onOpenChanges
            ),
            pasteCommand(model),
            toggleKeyboardCommand(model),
            AppCommand(
                id: "app.commandPalette",
                title: "Command Palette",
                keyEquivalent: AppKeyEquivalent(key: .k),
                isEnabled: { true },
                handler: onOpenPalette
            ),
        ]
    }

    private static let noActiveSession = "No active session"
    private static let oneSessionOpen = "One session open"
    private static let noMultiplexer = "No multiplexer on this host"
    private static let noWorkspace = "No workspace resolved"

    private static let ordinals = [
        "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
    ]

    private static let digitKeys: [HardwareKeyCode] = [
        .one, .two, .three, .four, .five, .six, .seven, .eight, .nine,
    ]

    private static func sessionCommands(_ model: SessionWorkspaceModel) -> [AppCommand] {
        zip(digitKeys, ordinals).enumerated().map { index, pair in
            let (key, ordinal) = pair
            let number = index + 1
            return AppCommand(
                id: "session.activate\(ordinal)",
                title: "Session \(number)",
                keyEquivalent: AppKeyEquivalent(key: key),
                isEnabled: { model.registry.count >= number },
                disabledReason: {
                    model.registry.count >= number ? nil : "\(model.registry.count) sessions open"
                },
                handler: { switchTo(model, at: index) }
            )
        }
    }

    private static func pasteCommand(_ model: SessionWorkspaceModel) -> AppCommand {
        AppCommand(
            id: "app.paste",
            title: "Paste",
            keyEquivalent: AppKeyEquivalent(key: .v),
            isEnabled: { model.activeSessionID != nil },
            disabledReason: { model.activeSessionID == nil ? noActiveSession : nil },
            handler: {
                guard let id = model.activeSessionID, let surface = model.surface(for: id) else {
                    return
                }
                guard let text = SystemClipboardPasteboard().read(), !text.isEmpty else { return }
                let bytes = PastePayload(text).bytes(mode: TerminalInputMode())
                surface.engine.emitInput(ArraySlice(bytes))
            }
        )
    }

    private static func toggleKeyboardCommand(_ model: SessionWorkspaceModel) -> AppCommand {
        AppCommand(
            id: "app.toggleKeyboard",
            title: "Toggle Keyboard",
            keyEquivalent: nil,
            isEnabled: { model.activeSessionID != nil },
            disabledReason: { model.activeSessionID == nil ? noActiveSession : nil },
            handler: {
                guard let id = model.activeSessionID, let surface = model.surface(for: id) else {
                    return
                }
                #if canImport(UIKit)
                let terminalView = surface.engine.surface
                if terminalView.isFirstResponder {
                    _ = terminalView.resignFirstResponder()
                } else {
                    _ = terminalView.becomeFirstResponder()
                }
                #endif
            }
        )
    }

    private static func step(_ model: SessionWorkspaceModel, by delta: Int) {
        let sessions = model.registry.sessions
        guard let active = model.activeSessionID,
            let index = model.registry.index(of: active),
            !sessions.isEmpty
        else {
            return
        }
        switchTo(model, at: (index + delta + sessions.count) % sessions.count)
    }

    private static func switchTo(_ model: SessionWorkspaceModel, at index: Int) {
        let sessions = model.registry.sessions
        guard sessions.indices.contains(index) else { return }
        let id = sessions[index].id
        model.beginSwitch(to: id)
        Task { await model.completeSwitch() }
    }
}
