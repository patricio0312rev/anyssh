import AnySSHUI
import SwiftUI

struct ScenarioSheet<Content: View>: View {
    @State private var isPresented = true

    private let content: (@escaping () -> Void) -> Content

    init(@ViewBuilder content: @escaping (@escaping () -> Void) -> Content) {
        self.content = content
    }

    var body: some View {
        Theme.surface.base
            .ignoresSafeArea()
            .sheet(isPresented: $isPresented) {
                content { isPresented = false }
            }
    }
}
