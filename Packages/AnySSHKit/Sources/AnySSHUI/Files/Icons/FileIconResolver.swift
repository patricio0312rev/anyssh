import Foundation

public nonisolated enum FileIconResolver: Sendable {
    public static func icon(forFile fileName: String) -> FileIconName {
        let base = (fileName as NSString).lastPathComponent.lowercased()
        if base.isEmpty {
            return .file
        }
        if let exact = FileIconTables.fileNames[base] {
            return FileIconName(exact)
        }
        if let matched = longestExtension(in: base) {
            return FileIconName(matched)
        }
        return .file
    }

    public static func icon(forFolder folderName: String, expanded: Bool = false, isRoot: Bool = false)
        -> FileIconName
    {
        if isRoot {
            return expanded ? .folderRootOpen : .folderRoot
        }
        let base = (folderName as NSString).lastPathComponent.lowercased()
        if let matched = FileIconTables.folderNames[base] {
            let name = expanded ? "\(matched)-open" : matched
            return FileIconName(name)
        }
        return expanded ? .folderOpen : .folder
    }

    public static var shippedIconNames: Set<String> {
        FileIconTables.shippedIconNames
    }

    public static var mappedIconNames: Set<String> {
        var names = Set<String>()
        names.insert(FileIconName.file.rawValue)
        names.insert(FileIconName.folder.rawValue)
        names.insert(FileIconName.folderOpen.rawValue)
        names.insert(FileIconName.folderRoot.rawValue)
        names.insert(FileIconName.folderRootOpen.rawValue)
        names.formUnion(FileIconTables.fileNames.values)
        names.formUnion(FileIconTables.fileExtensions.values)
        for base in FileIconTables.folderNames.values {
            names.insert(base)
            names.insert("\(base)-open")
        }
        return names
    }

    private static func longestExtension(in fileName: String) -> String? {
        guard fileName.contains(".") else { return nil }
        var bestIcon: String?
        var bestLength = -1
        var start = fileName.startIndex
        while let dot = fileName[start...].firstIndex(of: ".") {
            let extStart = fileName.index(after: dot)
            guard extStart < fileName.endIndex else { break }
            let ext = String(fileName[extStart...])
            if let icon = FileIconTables.fileExtensions[ext], ext.count > bestLength {
                bestIcon = icon
                bestLength = ext.count
            }
            start = extStart
        }
        return bestIcon
    }
}
