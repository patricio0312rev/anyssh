import AnySSHCore
import Foundation
import Observation

@MainActor
@Observable
public final class JSONViewerModel {
    public enum State: Equatable {
        case loading
        case refusal(ErrorState)
        case content
        case failed(ErrorState)
    }

    public enum Mode: Equatable {
        case text
        case tree
    }

    public static let formatCap = 512 * 1024
    public static let cap = 2 * 1024 * 1024

    public private(set) var state: State = .loading
    public private(set) var mode: Mode = .text
    public private(set) var displayText = ""
    public private(set) var displayTokens: [LineTokens] = []
    public private(set) var tree: JSONTreeModel?
    public private(set) var originalByteCount = 0

    public var canFormat: Bool {
        originalByteCount <= Self.formatCap
    }

    private let loader: BlobTextLoader
    private let highlighter: any SyntaxHighlighter
    private var root: JSONNode?

    public init(
        ref: BlobRef,
        service: any BlobService,
        highlighter: any SyntaxHighlighter,
        mode: Mode = .text
    ) {
        self.loader = BlobTextLoader(ref: ref, service: service, cap: Self.cap)
        self.highlighter = highlighter
        self.mode = mode
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
            originalByteCount = loader.byteCount
            displayText = text
            displayTokens = await highlighter.tokens(for: text, language: .json)
            root = try? JSONTextParser.parse(text)
            tree = root.map(JSONTreeModel.init)
            state = .content
        }
    }

    public func openAnyway() async {
        loader.allowOverCap()
        await load()
    }

    public func format() async {
        guard mode == .text, canFormat, let root else { return }
        let pretty = JSONPrettyPrinter.print(root, indent: 2, sortedKeys: true)
        displayText = pretty
        displayTokens = await highlighter.tokens(for: pretty, language: .json)
    }

    public func select(_ mode: Mode) {
        self.mode = mode
    }

    public func retry() async {
        await load()
    }
}
