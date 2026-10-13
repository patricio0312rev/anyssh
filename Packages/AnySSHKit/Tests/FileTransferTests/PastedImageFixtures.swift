import AnySSHCore
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum PastedImageFixtures {
    struct Unbuildable: Error {}

    static func png(width: Int, height: Int, noisy: Bool = false) throws -> PastedImage {
        let pixels = try draw(width: width, height: height, noisy: noisy)
        return PastedImage(data: try encode(pixels, as: .png), format: .png)
    }

    static func jpeg(width: Int, height: Int) throws -> PastedImage {
        let pixels = try draw(width: width, height: height, noisy: true)
        return PastedImage(data: try encode(pixels, as: .jpeg), format: .jpeg)
    }

    static func data(width: Int, height: Int, as type: UTType) throws -> Data {
        try encode(try draw(width: width, height: height, noisy: true), as: type)
    }

    static func pixelSize(of image: PastedImage) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithData(image.data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Int,
            let height = properties[kCGImagePropertyPixelHeight] as? Int
        else { return nil }
        return (width, height)
    }

    private static func draw(width: Int, height: Int, noisy: Bool) throws -> CGImage {
        var generator = SystemRandomNumberGenerator()
        let bytes = (0..<(width * height * 4)).map { index -> UInt8 in
            guard noisy else { return index % 4 == 3 ? 255 : 128 }
            return index % 4 == 3 ? 255 : UInt8.random(in: 0...255, using: &generator)
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
            let space = CGColorSpace(name: CGColorSpace.sRGB),
            let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: space,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else { throw Unbuildable() }
        return image
    }

    private static func encode(_ image: CGImage, as type: UTType) throws -> Data {
        let output = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                output as CFMutableData, type.identifier as CFString, 1, nil)
        else { throw Unbuildable() }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw Unbuildable() }
        return output as Data
    }
}
