import AnySSHUI
import SwiftUI

@main
struct AnySSHApp: App {
    private let environment = AppEnvironment(mode: .current())

    var body: some Scene {
        WindowGroup {
            RootView(environment: environment)
        }
        .defaultSize(width: 1000, height: 700)
        .windowResizability(.contentSize)
    }
}
