#if canImport(UIKit)
import UIKit

@MainActor
public final class SessionBackgroundTask {
    public typealias ExpirationHandler = @MainActor () -> Void

    private var taskID = UIBackgroundTaskIdentifier.invalid
    private let name: String

    public init(name: String = "anyssh.session.suspend") {
        self.name = name
    }

    public var isActive: Bool {
        taskID != .invalid
    }

    public func begin(onExpire: @escaping ExpirationHandler = {}) {
        end()
        taskID = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            Task { @MainActor in
                onExpire()
                self?.end()
            }
        }
    }

    public func end() {
        guard taskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(taskID)
        taskID = .invalid
    }
}
#endif
