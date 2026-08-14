import AnySSHCore
import Foundation

public enum NumstatMerge {
    public static func apply(_ counts: [ChangedFile], to files: [ChangedFile]) -> [ChangedFile] {
        guard !counts.isEmpty else { return files }
        var byPath = [String: ChangedFile]()
        for count in counts {
            if let path = count.newPath { byPath[path] = count }
            if let path = count.oldPath { byPath[path] = count }
        }
        return files.map { file in
            guard let match = file.newPath.flatMap({ byPath[$0] }) ?? file.oldPath.flatMap({ byPath[$0] })
            else { return file }
            return ChangedFile(
                oldPath: file.oldPath,
                newPath: file.newPath,
                change: file.change,
                isBinary: file.isBinary || match.isBinary,
                additions: match.additions,
                deletions: match.deletions
            )
        }
    }
}
