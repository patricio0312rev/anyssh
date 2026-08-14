import Foundation

nonisolated public enum MarkdownURLRewriter {
    public static func rewrittenURL(for destination: String, relativeTo filePath: String) -> String {
        guard !hasScheme(destination) else { return destination }
        let (pathPart, suffix) = splitSuffix(destination)
        let resolved = resolve(pathPart, relativeTo: filePath)
        let encoded = percentEncodePath(resolved)
        return "\(MarkdownImageURL.scheme)://\(MarkdownImageURL.host)/\(encoded)\(suffix)"
    }

    private static func hasScheme(_ destination: String) -> Bool {
        guard let colon = destination.firstIndex(of: ":") else { return false }
        guard let first = destination.first, first.isLetter else { return false }
        let scheme = destination[..<colon]
        return scheme.allSatisfy {
            $0.isLetter || $0.isNumber || $0 == "+" || $0 == "-" || $0 == "."
        }
    }

    private static func splitSuffix(_ destination: String) -> (path: String, suffix: String) {
        let query = destination.firstIndex(of: "?")
        let fragment = destination.firstIndex(of: "#")
        let cut: String.Index?
        switch (query, fragment) {
        case (let q?, let f?): cut = Swift.min(q, f)
        case (let q?, nil): cut = q
        case (nil, let f?): cut = f
        case (nil, nil): cut = nil
        }
        guard let cut else { return (destination, "") }
        return (String(destination[..<cut]), String(destination[cut...]))
    }

    private static func resolve(_ pathPart: String, relativeTo filePath: String) -> String {
        var segments: [String]
        if pathPart.hasPrefix("/") {
            segments = pathPart.split(separator: "/").map(String.init)
        } else {
            let directory = filePath.split(separator: "/").dropLast().map(String.init)
            segments = directory + pathPart.split(separator: "/").map(String.init)
        }
        var stack: [String] = []
        stack.reserveCapacity(segments.count)
        for segment in segments {
            switch segment {
            case ".":
                continue
            case "..":
                if !stack.isEmpty { stack.removeLast() }
            default:
                stack.append(segment)
            }
        }
        return stack.joined(separator: "/")
    }

    private static func percentEncodePath(_ path: String) -> String {
        var encoded = ""
        encoded.reserveCapacity(path.utf8.count)
        for byte in path.utf8 {
            if byte < 128, allowedBytes.contains(byte) {
                encoded.append(Character(UnicodeScalar(byte)))
            } else {
                encoded.append("%")
                encoded.append(String(format: "%02X", byte))
            }
        }
        return encoded
    }

    private static let allowedBytes: Set<UInt8> = Set(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~/".utf8
    )
}
