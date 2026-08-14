import AnySSHCore
import Foundation
import Observation

@MainActor
@Observable
public final class SourceViewerModel {
    public enum State: Equatable {
        case loading
        case refusal(ErrorState)
        case content(SourceDocument)
        case failed(ErrorState)
    }

    public struct SourceDocument: Equatable {
        public let text: String
        public let tokens: [LineTokens]
        public let byteCount: Int

        public init(text: String, tokens: [LineTokens], byteCount: Int) {
            self.text = text
            self.tokens = tokens
            self.byteCount = byteCount
        }
    }

    public static let cap = 2 * 1024 * 1024

    public private(set) var state: State = .loading

    private let loader: BlobTextLoader
    private let highlighter: any SyntaxHighlighter
    private let language: LanguageID

    public init(
        ref: BlobRef,
        service: any BlobService,
        highlighter: any SyntaxHighlighter,
        language: LanguageID,
        cap: Int = SourceViewerModel.cap
    ) {
        self.loader = BlobTextLoader(ref: ref, service: service, cap: cap)
        self.highlighter = highlighter
        self.language = language
    }

    public func load() async {
        await loader.load()
        switch loader.state {
        case .loading:
            state = .loading
        case .refusal(let error):
            state = .refusal(error)
        case .failed(let error):
            state = .failed(error)
        case .loaded(let text):
            let tokens = await highlighter.tokens(for: text, language: language)
            state = .content(
                SourceDocument(text: text, tokens: tokens, byteCount: loader.byteCount)
            )
        }
    }

    public func openAnyway() async {
        loader.allowOverCap()
        await load()
    }
}
