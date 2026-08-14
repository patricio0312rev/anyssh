import AnySSHCore
import SwiftUI

public protocol NoticeTextProviding: Sendable {
    func text(of notice: ThirdPartyNotice) -> String?
}

struct EmptyNoticeTextProvider: NoticeTextProviding {
    func text(of notice: ThirdPartyNotice) -> String? { nil }
}

private enum NoticeTextProviderKey: EnvironmentKey {
    static let defaultValue: any NoticeTextProviding = EmptyNoticeTextProvider()
}

extension EnvironmentValues {
    public var noticeTextProvider: any NoticeTextProviding {
        get { self[NoticeTextProviderKey.self] }
        set { self[NoticeTextProviderKey.self] = newValue }
    }
}
