import AnySSHCore
import Foundation
import GitClient
import Observation

@MainActor
@Observable
public final class ChangesListModel {
    public enum State {
        case loading
        case loaded(RepositoryStatus)
        case failure(ErrorState)
    }

    public private(set) var state: State = .loading
    public private(set) var repository: RepositoryRef?
    public let location: WorkspaceLocation
    public var gitService: any GitService { git }

    private let git: any GitService

    public init(location: WorkspaceLocation, git: any GitService) {
        self.location = location
        self.git = git
    }

    public func load() async {
        state = .loading
        do {
            let repository = try await git.repository(at: location)
            self.repository = repository
            state = .loaded(try await git.status(of: repository))
        } catch let error as GitParserError {
            state = .failure(error.state)
        } catch let error as ErrorState {
            state = .failure(error)
        } catch {
            state = .failure(.git(.notARepository))
        }
    }
}

extension GitParserError {
    fileprivate var state: ErrorState {
        if case .state(let state) = self { return state }
        return .git(.notARepository)
    }
}
