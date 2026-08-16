import Testing

@testable import AnySSHCore

@Suite struct ForegroundProcessCommandTests {
    private let probeOutput = """
        P bash
        P sh
        S /home/demo/src/api
        D /home/demo/src/api
        D /home/demo
        """

    @Test func theInteractiveShellDirectoryWinsOverDescendants() {
        #expect(ForegroundProcessCommand.workingDirectory(from: probeOutput) == "/home/demo/src/api")
    }

    @Test func aDescendantDirectoryIsUsedWhenTheShellReportsNone() {
        let output = "P vim\nD /srv/app\n"
        #expect(ForegroundProcessCommand.workingDirectory(from: output) == "/srv/app")
    }

    @Test func processNamesDropPathsAndLoginDashes() {
        let output = "P /usr/bin/python3\nP -bash\nP \n"
        #expect(ForegroundProcessCommand.processNames(from: output) == ["python3", "bash"])
    }

    @Test func theScriptFindsTheShellByItsSSHConnectionWhenThePortIsUnresolvable() {
        let script = ForegroundProcessCommand.script(clientPort: 1)
        #expect(script.contains(#"SSH_CONNECTION=[^ ]* $p "#))
        #expect(script.contains(#"readlink "/proc/$1/cwd""#))
    }
}
