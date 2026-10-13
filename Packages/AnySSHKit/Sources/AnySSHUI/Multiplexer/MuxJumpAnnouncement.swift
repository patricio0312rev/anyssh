@MainActor
enum MuxJumpAnnouncement {
    static func present(on toasts: StatusToastCenter, target: String, model: JumpToModel) {
        guard case .focusedElsewhere(let session) = model.lastOutcome else {
            toasts.present(severity: .success, title: MuxNavigationCopy.jumped(to: target))
            return
        }
        toasts.present(
            severity: .attention,
            title: MuxNavigationCopy.focused(in: model.sessionName(of: session)),
            body: MuxNavigationCopy.detachToSwitch
        )
    }
}
