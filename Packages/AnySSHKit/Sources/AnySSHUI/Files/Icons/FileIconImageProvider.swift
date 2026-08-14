import SwiftUI

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public protocol FileIconImageProviding: Sendable {
    func image(for name: FileIconName) -> Image?
}

public struct BundleFileIconImageProvider: FileIconImageProviding {
    private let bundle: Bundle

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    public func image(for name: FileIconName) -> Image? {
        #if canImport(UIKit)
        guard UIImage(named: name.rawValue, in: bundle, with: nil) != nil else {
            return nil
        }
        #elseif canImport(AppKit)
        guard bundle.image(forResource: name.rawValue) != nil else {
            return nil
        }
        #endif
        return Image(name.rawValue, bundle: bundle)
    }
}

public struct StubFileIconImageProvider: FileIconImageProviding {
    private let names: Set<String>

    public init(names: Set<String> = FileIconResolver.shippedIconNames) {
        self.names = names
    }

    public func image(for name: FileIconName) -> Image? {
        names.contains(name.rawValue) ? Image(systemName: "doc") : nil
    }
}

private enum FileIconImageProviderKey: EnvironmentKey {
    static let defaultValue: any FileIconImageProviding = StubFileIconImageProvider()
}

extension EnvironmentValues {
    public var fileIconImageProvider: any FileIconImageProviding {
        get { self[FileIconImageProviderKey.self] }
        set { self[FileIconImageProviderKey.self] = newValue }
    }
}
