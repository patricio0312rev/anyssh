extension TreeSitterGrammar {
    var querySource: String {
        switch self {
        case .swift: SwiftHighlights.source
        case .typescript: TypeScriptHighlights.source
        case .javascript: JavaScriptHighlights.source
        case .python: PythonHighlights.source
        case .go: GoHighlights.source
        case .json: DataHighlights.json
        case .yaml: DataHighlights.yaml
        case .markdown: DataHighlights.markdown
        }
    }
}
