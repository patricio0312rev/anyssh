import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum ImageFixtures {
    public static let beforeSize = CGSize(width: 320, height: 200)
    public static let afterSize = CGSize(width: 360, height: 200)

    public static let before = png(size: beforeSize, bars: 4, seed: 0)
    public static let after = png(size: afterSize, bars: 6, seed: 1)

    public static func image(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private static let palette: [(red: CGFloat, green: CGFloat, blue: CGFloat)] = [
        (0xff / 255, 0x61 / 255, 0x88 / 255),
        (0xa9 / 255, 0xdc / 255, 0x76 / 255),
        (0xff / 255, 0xd8 / 255, 0x66 / 255),
        (0xfc / 255, 0x98 / 255, 0x67 / 255),
        (0xab / 255, 0x9d / 255, 0xf2 / 255),
        (0x78 / 255, 0xdc / 255, 0xe8 / 255),
    ]

    private static func png(size: CGSize, bars: Int, seed: Int) -> Data {
        guard let image = render(size: size, bars: bars, seed: seed) else { return Data() }
        return encode(image) ?? Data()
    }

    private static func render(size: CGSize, bars: Int, seed: Int) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }
        context.setFillColor(red: 0x2d / 255, green: 0x2a / 255, blue: 0x2e / 255, alpha: 1)
        context.fill(CGRect(origin: .zero, size: size))
        let barWidth = size.width / CGFloat(bars)
        for index in 0..<bars {
            let color = palette[(index + seed) % palette.count]
            context.setFillColor(red: color.red, green: color.green, blue: color.blue, alpha: 1)
            let inset = CGFloat(index % 3) * 12
            context.fill(
                CGRect(
                    x: CGFloat(index) * barWidth,
                    y: inset,
                    width: barWidth - 6,
                    height: size.height - inset * 2
                )
            )
        }
        return context.makeImage()
    }

    private static func encode(_ image: CGImage) -> Data? {
        let output = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                output, UTType.png.identifier as CFString, 1, nil
            )
        else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
