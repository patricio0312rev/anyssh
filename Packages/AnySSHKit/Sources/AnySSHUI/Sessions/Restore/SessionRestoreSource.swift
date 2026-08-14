import AnySSHCore
import Sessions

@MainActor
public protocol SessionRestoreSource: AnyObject {
    var registry: SessionRegistry { get }
    var activeSessionID: SessionID? { get }

    func screenDump(for id: SessionID) -> String?
}
