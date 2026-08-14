import AnySSHCore
import Testing

@testable import GitClient

@Suite struct GitRepositoryRefTests {
    @Test func defaultsToTheMainBranch() {
        let ref = GitRepositoryRef(remoteID: RemoteID(rawValue: "mini"), path: "/srv/app")
        #expect(ref.branch == "main")
    }

    @Test func refsToTheSamePathOnDifferentRemotesAreDistinct() {
        let mini = GitRepositoryRef(remoteID: RemoteID(rawValue: "mini"), path: "/srv/app")
        let vps = GitRepositoryRef(remoteID: RemoteID(rawValue: "vps"), path: "/srv/app")
        #expect(mini != vps)
    }

    @Test func pathsAreCarriedVerbatimIncludingCharactersAShellWouldMangle() {
        let ref = GitRepositoryRef(remoteID: RemoteID(rawValue: "mini"), path: "/srv/my app/it's here")
        #expect(ref.path == "/srv/my app/it's here")
    }
}
