import Foundation

public struct BatchNonce: Hashable, Sendable {
    public static let digits = 32

    public let hex: String

    public init() {
        let high = UInt64.random(in: .min ... .max)
        let low = UInt64.random(in: .min ... .max)
        hex = String(format: "%016llx%016llx", high, low)
    }

    public init?(hex: String) {
        guard hex.count == Self.digits, hex.allSatisfy(Self.isDigit) else { return nil }
        self.hex = hex
    }

    public var delimiter: Data { Data("\n--\(hex)--".utf8) }

    private static func isDigit(_ character: Character) -> Bool {
        character.isASCII && (character.isNumber || ("a"..."f").contains(character))
    }
}
