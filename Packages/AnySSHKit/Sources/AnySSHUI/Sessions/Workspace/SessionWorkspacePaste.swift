#if canImport(UIKit)
import AnySSHCore
import SwiftUI
import TerminalEmulator

extension SessionWorkspaceView {
    func pasteFromClipboard() {
        guard let id = model.activeSessionID, let surface = model.surface(for: id) else { return }
        switch PasteRoute.resolve(from: SystemClipboardPasteboard()) {
        case .text(let text):
            emitPaste(text, into: surface)
        case .image(let data):
            uploadAndPaste(into: id) { await imagePaste.upload(contentsOf: data, over: $0) }
        case .unreadableImage:
            presentImagePasteFailure(.unreadable)
        case .empty:
            toasts.present(
                severity: .attention,
                title: ImagePasteCopy.emptyTitle,
                body: ImagePasteCopy.emptyBody,
                accessibilityIdentifier: UIIdentifier.Terminal.Clipboard.emptyToast
            )
        case .denied:
            toasts.present(state: .app(.clipboardDenied))
        }
    }

    private func emitPaste(_ text: String, into surface: TerminalSurface) {
        let mode = TerminalInputMode(bracketedPaste: surface.engine.pastesBracketed)
        surface.engine.emitInput(ArraySlice(PastePayload(text).bytes(mode: mode)))
    }

    func uploadAndPaste(
        into id: SessionID,
        upload: @escaping @MainActor (any RemoteConnection) async -> Result<String, ImagePasteFailure>
    ) {
        guard let connection = model.connection(for: id) else {
            toasts.present(state: .files(.fetchFailed))
            return
        }
        let progress = toasts.present(
            severity: .busy,
            title: ImagePasteCopy.uploadingTitle,
            body: ImagePasteCopy.uploadingBody,
            accessibilityIdentifier: UIIdentifier.Terminal.Clipboard.imageUploading
        )
        Task {
            let result = await upload(connection)
            toasts.retract(progress)
            let path: String
            switch result {
            case .success(let uploaded):
                path = uploaded
            case .failure(let failure):
                presentImagePasteFailure(failure)
                return
            }
            guard let surface = model.surface(for: id) else {
                presentImagePasteSuccess(title: ImagePasteCopy.uploadedTitle, path: path)
                return
            }
            emitPaste(ShellQuoting.quotedIfNeeded(path), into: surface)
            presentImagePasteSuccess(title: ImagePasteCopy.pastedTitle, path: path)
        }
    }

    private func presentImagePasteSuccess(title: String, path: String) {
        toasts.present(
            severity: .success,
            title: title,
            body: path,
            accessibilityIdentifier: UIIdentifier.Terminal.Clipboard.imagePasted
        )
    }

    private func presentImagePasteFailure(_ failure: ImagePasteFailure) {
        switch failure {
        case .transfer(let state):
            toasts.present(state: state)
        case .unreadable:
            toasts.present(
                severity: .error,
                title: ImagePasteCopy.unreadableTitle,
                body: ImagePasteCopy.unreadableBody,
                accessibilityIdentifier: UIIdentifier.Terminal.Clipboard.imageFailed
            )
        case .tooLarge:
            toasts.present(
                severity: .error,
                title: ImagePasteCopy.tooLargeTitle,
                body: ImagePasteCopy.tooLargeBody,
                accessibilityIdentifier: UIIdentifier.Terminal.Clipboard.imageFailed
            )
        case .photoUnavailable:
            toasts.present(
                severity: .error,
                title: ImagePasteCopy.photoUnavailableTitle,
                body: ImagePasteCopy.photoUnavailableBody,
                accessibilityIdentifier: UIIdentifier.Terminal.Clipboard.imageFailed
            )
        }
    }
}
#endif
