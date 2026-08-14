import Foundation

public enum DirectoryListingCommand {
    public static let label = "directory-listing"
    public static let entryLimit = 2000

    public static func batch(path: String, limit: Int = entryLimit) -> RemoteBatch {
        RemoteBatch(commands: [
            RemoteCommand(
                label: label,
                arguments: ["sh", "-c", script(path: path, limit: max(1, limit))],
                byteCap: 512 * 1024
            )
        ])
    }

    static func script(path: String, limit: Int) -> String {
        """
        cd -- \(ShellQuoting.singleQuote(path)) || exit 1
        __count=0
        __limit=\(limit)
        for __name in * .[!.]* ..?*; do
          [ -e "$__name" ] || [ -L "$__name" ] || continue
          if [ "$__count" -ge "$__limit" ]; then printf 'truncated\\0'; break; fi
          if [ -L "$__name" ]; then __kind=symlink
          elif [ -d "$__name" ]; then __kind=directory
          else __kind=file
          fi
          printf '%s\\t%s\\0' "$__kind" "$__name"
          __count=$((__count + 1))
        done
        """
    }

    public static func parse(_ data: Data, path: String) -> DirectoryListing {
        var entries = [DirectoryEntry]()
        var isTruncated = false
        for record in data.split(separator: 0, omittingEmptySubsequences: true) {
            let text = String(decoding: record, as: UTF8.self)
            if text == "truncated" {
                isTruncated = true
                continue
            }
            guard let separator = text.firstIndex(of: "\t") else { continue }
            let kind = DirectoryEntry.Kind(rawValue: String(text[text.startIndex..<separator]))
            let name = String(text[text.index(after: separator)...])
            guard let kind, !name.isEmpty else { continue }
            entries.append(DirectoryEntry(name: name, kind: kind))
        }
        return DirectoryListing(path: path, entries: entries, isTruncated: isTruncated)
    }
}
