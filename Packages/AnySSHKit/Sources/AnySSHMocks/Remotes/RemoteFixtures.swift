import AnySSHCore

public enum RemoteFixtures {
    public static let workstation = Remote(
        id: RemoteID(rawValue: "workstation"),
        name: "Workstation",
        host: "workstation.local",
        username: "patricio",
        startPath: "~/Sites/anyssh",
        tag: "home"
    )

    public static let buildBox = Remote(
        id: RemoteID(rawValue: "build-box"),
        name: "Build Box",
        host: "10.0.0.42",
        port: 2222,
        username: "ci",
        authMethod: .password,
        startupCommand: "tmux attach -t ci || tmux new -s ci",
        tag: "work"
    )

    public static let edgeNode = Remote(
        id: RemoteID(rawValue: "edge-node"),
        name: "Edge Node",
        host: "edge.example.net",
        username: "root",
        authMethod: .keyboardInteractive
    )

    public static func scenario(_ name: String) -> [Remote] {
        RemoteList(seed(name)).remotes
    }

    private static func seed(_ name: String) -> [Remote] {
        switch name {
        case "empty": []
        case "single": [workstation]
        case "many": many
        case "mixed": mixed
        default: mixed
        }
    }

    private static let mixed = [workstation, buildBox, edgeNode]

    private static let many =
        mixed
        + (1...9).map { index in
            Remote(
                id: RemoteID(rawValue: "node-\(index)"),
                name: "Node \(index)",
                host: "node\(index).cluster.internal",
                username: "deploy",
                tag: index.isMultiple(of: 2) ? "cluster" : nil
            )
        }
}
