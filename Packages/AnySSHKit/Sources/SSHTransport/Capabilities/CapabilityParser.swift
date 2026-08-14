import AnySSHCore
import Foundation

public enum CapabilityParseError: Error, Hashable, Sendable {
    case invalidUTF8
    case invalidHeader
    case duplicateField(String)
    case unknownField(String)
    case invalidField(String)
    case missingField(String)
}

public struct CapabilityParser: Sendable {
    public init() {}

    public func parse(_ bytes: Data) throws -> HostCapabilities {
        guard let text = String(data: bytes, encoding: .utf8) else {
            throw CapabilityParseError.invalidUTF8
        }
        var fields = [String: String]()
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        if lines.last == "" { lines.removeLast() }
        guard lines.first == "anyssh-capabilities/1" else {
            throw CapabilityParseError.invalidHeader
        }
        for line in lines.dropFirst() {
            let parts = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { throw CapabilityParseError.invalidField(String(line)) }
            let key = String(parts[0])
            guard Self.keys.contains(key) else { throw CapabilityParseError.unknownField(key) }
            guard fields.updateValue(String(parts[1]), forKey: key) == nil else {
                throw CapabilityParseError.duplicateField(key)
            }
        }

        for key in Self.requiredKeys where fields[key] == nil {
            throw CapabilityParseError.missingField(key)
        }
        guard let shell = fields["shell"], let platform = fields["platform"],
            let locale = fields["locale"], let home = fields["home"], let path = fields["path"]
        else { throw CapabilityParseError.invalidField("host") }

        return HostCapabilities(
            shell: shell,
            platform: platform,
            locale: locale,
            home: home,
            searchPath: path,
            model: fields["model"],
            product: fields["product"],
            git: try tool(fields, name: "git"),
            tmux: try tool(fields, name: "tmux"),
            herdr: HerdrReport(
                tool: try tool(fields, name: "herdr"),
                protocolVersion: try protocolVersion(fields["herdr.protocol"] ?? "")
            )
        )
    }

    private func tool(_ fields: [String: String], name: String) throws -> ToolReport {
        guard let path = fields["\(name).path"], let rawVersion = fields["\(name).version"] else {
            throw CapabilityParseError.missingField(name)
        }
        if path.isEmpty {
            guard rawVersion.isEmpty else { throw CapabilityParseError.invalidField(name) }
            return ToolReport(path: nil, version: nil)
        }
        guard path.hasPrefix("/") else { throw CapabilityParseError.invalidField(name) }
        return ToolReport(path: path, version: Self.version(from: rawVersion))
    }

    private func protocolVersion(_ value: String) throws -> Int? {
        guard value.isEmpty else {
            guard let version = Int(value), version >= 0 else {
                throw CapabilityParseError.invalidField("herdr.protocol")
            }
            return version
        }
        return nil
    }

    private static func version(from text: String) -> String? {
        let scalars = Array(text)
        for start in scalars.indices where scalars[start].isNumber {
            var value = ""
            var index = start
            var suffix = false
            while index < scalars.endIndex {
                let scalar = scalars[index]
                if scalar.isNumber || (!suffix && scalar == ".") {
                    value.append(scalar)
                } else if scalar.isLetter, !value.isEmpty {
                    suffix = true
                    value.append(scalar)
                } else {
                    break
                }
                index += 1
            }
            if HostVersion(rawValue: value) != nil { return value }
        }
        return nil
    }

    private static let keys: Set<String> = [
        "shell", "platform", "model", "product", "locale", "home", "path",
        "git.path", "git.version", "tmux.path", "tmux.version",
        "herdr.path", "herdr.version", "herdr.protocol",
    ]

    private static let requiredKeys: Set<String> = [
        "shell", "platform", "locale", "home", "path",
        "git.path", "git.version", "tmux.path", "tmux.version",
        "herdr.path", "herdr.version", "herdr.protocol",
    ]
}
