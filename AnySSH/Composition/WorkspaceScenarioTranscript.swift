enum WorkspaceScenarioTranscript {
    static let shell = """
        Last login: Mon Aug 10 09:41:22 on ttys001\r
        dev@workstation ~/src/api % git status --short\r
         M Sources/API/Routes/SessionRoutes.swift\r
        ?? docs/plan-session-routes.md\r
        dev@workstation ~/src/api % swift build\r
        Building for debugging...\r
        [128/128] Compiling API SessionRoutes.swift\r
        Build complete! (18.42s)\r
        dev@workstation ~/src/api % \r
        """

    static let multiplexed = """
        [ci] tmux attach -t ci\r
        [0] 0:make* 1:tests- 2:deploy\r
        ci@build-box /srv/ci/api $ make test\r
        Test run with 832 tests in 188 suites passed after 5.3 seconds.\r
        ci@build-box /srv/ci/api $ \r
        """
}
