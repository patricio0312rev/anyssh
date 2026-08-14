import SwiftTreeSitter
import TreeSitterGo
import TreeSitterJSON
import TreeSitterJavaScript
import TreeSitterMarkdown
import TreeSitterPython
import TreeSitterSwift
import TreeSitterTypeScript
import TreeSitterYAML

public enum TreeSitterGrammar: String, CaseIterable, Sendable {
    case swift
    case typescript
    case javascript
    case python
    case go
    case json
    case yaml
    case markdown

    public var language: Language {
        switch self {
        case .swift: Language(tree_sitter_swift())
        case .typescript: Language(tree_sitter_typescript())
        case .javascript: Language(tree_sitter_javascript())
        case .python: Language(tree_sitter_python())
        case .go: Language(tree_sitter_go())
        case .json: Language(tree_sitter_json())
        case .yaml: Language(tree_sitter_yaml())
        case .markdown: Language(tree_sitter_markdown())
        }
    }
}

extension TreeSitterGrammar {
    public static var runtimeABIVersion: Int { Language.version }

    public static var minimumSupportedABIVersion: Int { Language.minimumCompatibleVersion }
}
