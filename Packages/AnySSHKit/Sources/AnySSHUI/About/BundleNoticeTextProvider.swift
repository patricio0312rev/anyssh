import AnySSHCore
import Foundation

public struct BundleNoticeTextProvider: NoticeTextProviding {
    private let bundle: Bundle

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    public func text(of notice: ThirdPartyNotice) -> String? {
        guard let url = bundle.url(forResource: notice.resource, withExtension: "txt") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
