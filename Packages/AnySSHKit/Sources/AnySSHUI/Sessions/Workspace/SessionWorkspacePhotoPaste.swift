#if canImport(UIKit)
import PhotosUI
import SwiftUI

extension SessionWorkspaceView {
    func pastePickedPhoto(_ item: PhotosPickerItem?) {
        guard let item, let id = model.activeSessionID else { return }
        pickedPhoto = nil
        uploadAndPaste(into: id) { connection in
            await imagePaste.uploadPhoto(over: connection) {
                try await item.loadTransferable(type: Data.self)
            }
        }
    }
}
#endif
