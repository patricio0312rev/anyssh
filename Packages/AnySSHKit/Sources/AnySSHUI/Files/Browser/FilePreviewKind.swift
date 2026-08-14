#if canImport(UIKit)
import Foundation
import SwiftDraw
import UIKit

enum FilePreviewKind {
    static let vectorExtensions: Set<String> = ["svg"]
    static let rasterExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "heic", "heif", "webp", "bmp", "tiff", "tif", "ico",
    ]

    static func isVector(_ name: String) -> Bool {
        vectorExtensions.contains(fileExtension(of: name))
    }

    static func isRaster(_ name: String) -> Bool {
        rasterExtensions.contains(fileExtension(of: name))
    }

    static func vectorImage(from data: Data) -> UIImage? {
        guard data.count <= SVGViewerModel.cap else { return nil }
        return SVG(data: data)?.rasterize()
    }

    private static func fileExtension(of name: String) -> String {
        (name as NSString).pathExtension.lowercased()
    }
}
#endif
