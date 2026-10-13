import AnySSHCore
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum ImagePasteEncoder {
    public enum Failure: Error, Equatable, Sendable {
        case unreadable
        case tooLarge
    }

    public static func image(from data: Data) throws -> PastedImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            CGImageSourceGetCount(source) > 0,
            let type = CGImageSourceGetType(source).flatMap({ UTType($0 as String) })
        else {
            throw Failure.unreadable
        }
        if type.conforms(to: .png) {
            return PastedImage(data: data, format: .png)
        }
        if type.conforms(to: .jpeg) {
            return PastedImage(data: data, format: .jpeg)
        }
        guard let jpeg = transcode(source) else { throw Failure.unreadable }
        return PastedImage(data: jpeg, format: .jpeg)
    }

    public static func fit(_ image: PastedImage, limits: ImagePasteLimits) throws -> PastedImage {
        guard let source = CGImageSourceCreateWithData(image.data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Int,
            let height = properties[kCGImagePropertyPixelHeight] as? Int
        else {
            throw Failure.unreadable
        }
        if limits.fits(byteCount: image.data.count, width: width, height: height) {
            return image
        }
        let scaled = try shrink(source, longestEdge: min(limits.maxPixelDimension, max(width, height)))
        if image.format == .png, let png = encode(scaled, as: .png, quality: nil),
            png.count <= limits.maxBytes
        {
            return PastedImage(data: png, format: .png)
        }
        for quality in limits.jpegQualities {
            guard let jpeg = encode(scaled, as: .jpeg, quality: quality) else { continue }
            if jpeg.count <= limits.maxBytes {
                return PastedImage(data: jpeg, format: .jpeg)
            }
        }
        throw Failure.tooLarge
    }

    private static func shrink(_ source: CGImageSource, longestEdge: Int) throws -> CGImage {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: longestEdge,
        ]
        guard let scaled = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw Failure.unreadable
        }
        return scaled
    }

    private static func transcode(_ source: CGImageSource) -> Data? {
        let output = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                output as CFMutableData,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else {
            return nil
        }
        let properties: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 1.0]
        CGImageDestinationAddImageFromSource(destination, source, 0, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }

    private static func encode(_ image: CGImage, as type: UTType, quality: Double?) -> Data? {
        let output = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                output as CFMutableData,
                type.identifier as CFString,
                1,
                nil
            )
        else {
            return nil
        }
        var properties: [CFString: Any] = [:]
        if let quality {
            properties[kCGImageDestinationLossyCompressionQuality] = quality
        }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
