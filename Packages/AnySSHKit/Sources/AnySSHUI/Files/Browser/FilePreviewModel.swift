#if canImport(UIKit)
import AnySSHCore
import Foundation
import Highlighting
import Observation
import UIKit

@MainActor
@Observable
public final class FilePreviewModel {
    public enum Rendering {
        case code(lines: [String], tokens: [LineTokens])
        case image(UIImage)
        case unreadable(ErrorState)
    }

    public enum State {
        case loading
        case loaded(Rendering)
        case failure(ErrorState)
    }

    public private(set) var state: State = .loading
    public private(set) var hasSource = false
    public var showsSource = false
    public private(set) var isTruncated = false
    private var sourceTokens: [LineTokens] = []

    private let path: String
    private let name: String
    private let browser: any RemoteFileBrowser
    private let highlighter: any SyntaxHighlighter
    private var source: String?

    public init(
        path: String,
        name: String,
        browser: any RemoteFileBrowser,
        highlighter: any SyntaxHighlighter
    ) {
        self.path = path
        self.name = name
        self.browser = browser
        self.highlighter = highlighter
    }

    public var rendering: Rendering? {
        guard case .loaded(let rendering) = state else { return nil }
        if showsSource, source != nil, let sourceRendering { return sourceRendering }
        return rendering
    }

    private var sourceRendering: Rendering? {
        guard let source else { return nil }
        return .code(lines: Self.lines(of: source), tokens: sourceTokens)
    }

    public func load() async {
        state = .loading
        do {
            let content = try await browser.read(path: path)
            isTruncated = content.isTruncated
            state = .loaded(await render(content))
        } catch let error as ErrorState {
            state = .failure(error)
        } catch {
            state = .failure(.files(.fetchFailed))
        }
    }

    private func render(_ content: FileContentCommand.Content) async -> Rendering {
        if FilePreviewKind.isVector(name) {
            let text = String(decoding: content.bytes, as: UTF8.self)
            source = text
            sourceTokens = await highlight(text)
            hasSource = true
            if let image = FilePreviewKind.vectorImage(from: content.bytes) { return .image(image) }
            return .code(lines: Self.lines(of: text), tokens: sourceTokens)
        }
        if FilePreviewKind.isRaster(name), let image = UIImage(data: content.bytes) {
            hasSource = false
            return .image(image)
        }
        guard !content.isBinary else { return .unreadable(.files(.binaryFile)) }
        let text = String(decoding: content.bytes, as: UTF8.self)
        return .code(lines: Self.lines(of: text), tokens: await highlight(text))
    }

    private func highlight(_ text: String) async -> [LineTokens] {
        let language = LanguageDetector().language(
            forPath: name,
            firstLine: text.split(separator: "\n", maxSplits: 1).first.map(String.init)
        )
        return await highlighter.tokens(for: text, language: language)
    }

    private static func lines(of text: String) -> [String] {
        var lines = text.components(separatedBy: "\n")
        if lines.last == "" { lines.removeLast() }
        return lines
    }
}
#endif
