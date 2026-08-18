#if canImport(UIKit)
import AnySSHCore
import Foundation
import SwiftUI
import TerminalEmulator

extension SessionWorkspaceView {
    func handleGesture(_ slot: GestureSlot) {
        switch slot {
        case .swipeLeft:
            guard model.registry.count > 1 else { return }
            switchEdge = .trailing
            commandRegistry.run(id: "session.next")
        case .swipeRight:
            guard model.registry.count > 1 else { return }
            switchEdge = .leading
            commandRegistry.run(id: "session.previous")
        }
    }

    func send(_ text: String) {
        guard let id = model.activeSessionID, let connection = model.connection(for: id) else {
            return
        }
        let bytes = Array(text.utf8)
        guard !bytes.isEmpty else { return }
        Task { try? await connection.sendDisplay(bytes[...]) }
    }

    func toggleDictation() {
        Task {
            guard dictation.isListening else {
                dictation.onFinish = { text in send(text) }
                await dictation.start()
                return
            }
            dictation.stop()
        }
    }

    func importPicked(_ result: Result<URL, any Error>) {
        guard case .success(let file) = result else {
            toasts.present(state: .files(.fetchFailed))
            return
        }
        guard let id = model.activeSessionID, let connection = model.connection(for: id) else {
            return
        }
        Task {
            if let path = await fileImport.upload(file, over: connection) {
                send(path)
                toasts.present(
                    severity: .success,
                    title: "Uploaded \(file.lastPathComponent)",
                    body: path,
                    accessibilityIdentifier: FileImportIdentifier.toast
                )
            } else if case .failed(let state) = fileImport.outcome {
                toasts.present(state: state)
            }
        }
    }

    func dismissToRemotes() {
        isSwitcherPresented = false
        isPalettePresented = false
        reclaimHardwareKeyboard()
        onClose?()
    }

    @ViewBuilder
    func browserSheet(_ mode: WorkspaceBrowserMode) -> some View {
        if let record = model.activeRecord, let connection = model.connection(for: record.id) {
            let services = model.makeBrowserServices(connection, record.remoteID)
            WorkspaceBrowserSheet(
                location: record.workspace,
                mode: mode,
                resolve: { [weak model] in
                    await model?.resolveWorkspaceForActiveSession()
                    return await model?.activeRecord?.workspace
                },
                git: services.git,
                files: services.files
            )
        } else {
            ErrorStateView(state: .git(.notARepository))
        }
    }
}
#endif
