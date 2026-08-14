import Foundation

public enum CursorProjectResolver: Sendable {
    public static func isNoise(_ encoded: String) -> Bool {
        let name = encoded.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !name.isEmpty else { return true }
        if name.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }) {
            return true
        }
        if name.contains("var-folders-") { return true }
        if name.hasPrefix("T-") { return true }
        return false
    }

    public static func resolve(
        encoded: String,
        isDirectory: (String) -> Bool
    ) -> String? {
        let name = encoded.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !isNoise(name) else { return nil }
        return search(Array(name), index: 0, path: "", isDirectory: isDirectory)
    }

    public static func parseListing(
        _ bytes: Data,
        isDirectory: (String) -> Bool = { _ in true }
    ) -> [RecentDirectorySighting] {
        guard let text = String(data: bytes, encoding: .utf8) else { return [] }
        var sightings = [RecentDirectorySighting]()
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let parts = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2, let ms = Double(parts[1]) else { continue }
            let token = String(parts[0])
            let path: String
            if token.hasPrefix("/") {
                path = token
            } else if let resolved = resolve(encoded: token, isDirectory: isDirectory) {
                path = resolved
            } else {
                continue
            }
            guard !path.isEmpty else { continue }
            sightings.append(
                RecentDirectorySighting(
                    path: path,
                    source: .cursor,
                    lastUsed: Date(timeIntervalSince1970: ms / 1000)
                )
            )
        }
        return sightings
    }

    private static func search(
        _ chars: [Character],
        index: Int,
        path: String,
        isDirectory: (String) -> Bool
    ) -> String? {
        if index >= chars.count {
            return path.isEmpty ? nil : (isDirectory(path) ? path : nil)
        }
        var cursor = index
        var component = ""
        while cursor < chars.count {
            let scalar = chars[cursor]
            if scalar == "-" {
                let candidate = path + "/" + component
                if isDirectory(candidate),
                    let found = search(
                        chars,
                        index: cursor + 1,
                        path: candidate,
                        isDirectory: isDirectory
                    )
                {
                    return found
                }
                component.append("-")
                cursor += 1
            } else {
                component.append(scalar)
                cursor += 1
            }
        }
        let candidate = path + "/" + component
        return isDirectory(candidate) ? candidate : nil
    }
}
