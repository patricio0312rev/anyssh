import SwiftUI

private enum StatusToastCenterKey: EnvironmentKey {
    static let defaultValue = StatusToastCenter()
}

extension EnvironmentValues {
    public var statusToasts: StatusToastCenter {
        get { self[StatusToastCenterKey.self] }
        set { self[StatusToastCenterKey.self] = newValue }
    }
}

extension View {
    public func statusToastCenter(_ center: StatusToastCenter) -> some View {
        environment(\.statusToasts, center)
    }
}
