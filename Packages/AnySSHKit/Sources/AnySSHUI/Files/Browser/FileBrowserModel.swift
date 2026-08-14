import AnySSHCore
import Foundation
import Observation

@MainActor
@Observable
public final class FileBrowserModel {
    public enum State {
        case loading
        case loaded(DirectoryListing)
        case failure(ErrorState)
    }

    public private(set) var state: State = .loading
    public private(set) var path: String

    private let root: String
    let browser: any RemoteFileBrowser

    public init(root: String, browser: any RemoteFileBrowser) {
        self.root = root
        path = root
        self.browser = browser
    }

    public var isAtRoot: Bool { path == root }

    public var breadcrumb: [String] {
        guard path.hasPrefix(root) else { return [displayName(of: path)] }
        let relative = path.dropFirst(root.count).split(separator: "/").map(String.init)
        return [displayName(of: root)] + relative
    }

    public func load() async {
        state = .loading
        do {
            state = .loaded(try await browser.list(path: path))
        } catch let error as ErrorState {
            state = .failure(error)
        } catch {
            state = .failure(.files(.fetchFailed))
        }
    }

    public func enter(_ entry: DirectoryEntry) async {
        path = join(path, entry.name)
        await load()
    }

    public func goUp() async {
        guard !isAtRoot else { return }
        path = String(path[path.startIndex..<(path.lastIndex(of: "/") ?? path.endIndex)])
        if path.isEmpty { path = "/" }
        await load()
    }

    public func fullPath(of entry: DirectoryEntry) -> String {
        join(path, entry.name)
    }

    private func join(_ base: String, _ name: String) -> String {
        base.hasSuffix("/") ? base + name : base + "/" + name
    }

    private func displayName(of path: String) -> String {
        path.split(separator: "/").last.map(String.init) ?? "/"
    }
}
