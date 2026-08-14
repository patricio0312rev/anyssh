import Foundation

public enum TerminalSelectionContext: Equatable, Sendable {
    case none
    case url(String)
    case path(String)

    public static func detect(in text: String) -> Self {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.allSatisfy({ !$0.isWhitespace }) else { return .none }
        if let url = URL(string: value), let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme), url.host != nil
        {
            return .url(value)
        }
        if value.contains("/") {
            return .path(value)
        }
        return .none
    }
}
