import Foundation

public enum JSONPrettyPrinter {
    public static func print(_ node: JSONNode, indent: Int = 2, sortedKeys: Bool = false) -> String {
        var output = ""
        write(node, depth: 0, indent: indent, sortedKeys: sortedKeys, into: &output)
        return output
    }

    private static func write(
        _ node: JSONNode,
        depth: Int,
        indent: Int,
        sortedKeys: Bool,
        into output: inout String
    ) {
        switch node {
        case .object(let children):
            writeObject(children, depth: depth, indent: indent, sortedKeys: sortedKeys, into: &output)
        case .array(let children):
            writeArray(children, depth: depth, indent: indent, sortedKeys: sortedKeys, into: &output)
        case .string(let value):
            output += "\"\(Self.escaped(value))\""
        case .number(let raw):
            output += raw
        case .boolean(let value):
            output += value ? "true" : "false"
        case .null:
            output += "null"
        }
    }

    private static func writeObject(
        _ children: [(key: String, value: JSONNode)],
        depth: Int,
        indent: Int,
        sortedKeys: Bool,
        into output: inout String
    ) {
        let ordered = sortedKeys ? children.sorted { $0.key < $1.key } : children
        guard !ordered.isEmpty else {
            output += "{}"
            return
        }
        output += "{\n"
        for (index, child) in ordered.enumerated() {
            padding(depth + 1, indent, into: &output)
            output += "\"\(Self.escaped(child.key))\": "
            write(child.value, depth: depth + 1, indent: indent, sortedKeys: sortedKeys, into: &output)
            if index < ordered.count - 1 { output += "," }
            output += "\n"
        }
        padding(depth, indent, into: &output)
        output += "}"
    }

    private static func writeArray(
        _ children: [JSONNode],
        depth: Int,
        indent: Int,
        sortedKeys: Bool,
        into output: inout String
    ) {
        guard !children.isEmpty else {
            output += "[]"
            return
        }
        output += "[\n"
        for (index, child) in children.enumerated() {
            padding(depth + 1, indent, into: &output)
            write(child, depth: depth + 1, indent: indent, sortedKeys: sortedKeys, into: &output)
            if index < children.count - 1 { output += "," }
            output += "\n"
        }
        padding(depth, indent, into: &output)
        output += "]"
    }

    private static func padding(_ depth: Int, _ indent: Int, into output: inout String) {
        output += String(repeating: " ", count: depth * indent)
    }

    static func escaped(_ value: String) -> String {
        var output = ""
        for scalar in value.unicodeScalars {
            switch scalar.value {
            case 0x22: output += "\\\""
            case 0x5C: output += "\\\\"
            case 0x08: output += "\\b"
            case 0x0C: output += "\\f"
            case 0x0A: output += "\\n"
            case 0x0D: output += "\\r"
            case 0x09: output += "\\t"
            case 0x00...0x1F: output += String(format: "\\u%04x", scalar.value)
            default: output.unicodeScalars.append(scalar)
            }
        }
        return output
    }
}
