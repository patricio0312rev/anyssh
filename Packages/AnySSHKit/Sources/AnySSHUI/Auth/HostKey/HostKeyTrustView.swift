import SwiftUI

public struct HostKeyTrustView: View {
    @Bindable private var model: HostKeyTrustModel

    public init(model: HostKeyTrustModel) {
        _model = Bindable(wrappedValue: model)
    }

    public var body: some View {
        switch model.stage {
        case .idle:
            EmptyView()
        case .asking(let prompt) where prompt.isChanged:
            HostKeyChangeWarning(
                prompt: prompt,
                cancel: { model.cancel() },
                forget: { Task { await model.forgetHost() } }
            )
            .interactiveDismissDisabled()
        case .asking(let prompt):
            HostKeyFirstUseSheet(
                prompt: prompt,
                accept: { model.accept() },
                reject: { model.reject() },
                cancel: { model.cancel() }
            )
            .interactiveDismissDisabled()
        case .refused(let state):
            HostKeyRefusalView(state: state) { model.dismiss() }
        }
    }
}
