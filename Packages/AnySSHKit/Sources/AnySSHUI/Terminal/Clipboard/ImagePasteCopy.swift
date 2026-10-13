enum ImagePasteCopy {
    static let uploadingTitle = "Uploading image"
    static let uploadingBody = "Its path is pasted into the terminal once the host has it."
    static let pastedTitle = "Image pasted"
    static let uploadedTitle = "Image uploaded"
    static let emptyTitle = "Nothing to paste"
    static let emptyBody = "The clipboard holds no text and no image."
    static let unreadableTitle = "Image could not be read"
    static let unreadableBody =
        "The clipboard image is not a format this device can decode. Nothing was sent."
    static let tooLargeTitle = "Image too large"
    static let tooLargeBody = "It stays over the upload limit even after shrinking, so nothing was sent."
}
